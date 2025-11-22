#!/bin/bash
set -euo pipefail

#=========================================
# ComfyUI AI Photobooth - Vast.ai Provisioning Script
# Converted from Dockerfile v1.0
# Maintainer: stirproductionltd@gmail.com
# Optimized for RTX 4090 (CUDA 12.1)
#=========================================

#=========================================
# CONFIGURATION
#=========================================
export DEBIAN_FRONTEND=noninteractive
export TZ=UTC
export PYTHONUNBUFFERED=1

# Build configuration (equivalent to ARG in Dockerfile)
COMFYUI_REPO="${COMFYUI_REPO:-https://github.com/Stiryourmind/ComfyUI-v0.3.59-for-AI-booth.git}"
COMFYUI_BRANCH="${COMFYUI_BRANCH:-main}"

# Paths
APP_DIR="/workspace/app"
COMFYUI_DIR="${APP_DIR}/ComfyUI"

#=========================================
# LOGGING
#=========================================
LOG_FILE="/workspace/provisioning.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ ERROR: $*" >&2
    exit 1
}

log "========================================="
log "🚀 ComfyUI AI Photobooth Provisioning"
log "========================================="
log "Target: RTX 4090 (CUDA 12.1)"
log "Repository: ${COMFYUI_REPO}"
log "Branch: ${COMFYUI_BRANCH}"
log "========================================="

#=========================================
# TIMEZONE CONFIGURATION
#=========================================
log "🕐 Configuring timezone..."
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
echo $TZ > /etc/timezone

#=========================================
# SYSTEM DEPENDENCIES
#=========================================
log "📦 Installing system dependencies..."

# Update package lists
apt-get update || error "Failed to update package lists"

# Install initial dependencies
apt-get install -y --no-install-recommends \
    tzdata \
    software-properties-common \
    || error "Failed to install base packages"

# Add deadsnakes PPA for Python 3.11
log "📦 Adding Python 3.11 PPA..."
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update

# Install Python 3.11 and all dependencies
log "📦 Installing Python 3.11 and system libraries..."
apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3.11-distutils \
    git \
    build-essential \
    cmake \
    curl \
    libopencv-dev \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgl1 \
    libglx-mesa0 \
    fonts-dejavu-core \
    fontconfig \
    || error "Failed to install system dependencies"

# Install pip for Python 3.11
log "📦 Installing pip for Python 3.11..."
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# Set Python 3.11 as default
log "🔧 Setting Python 3.11 as default..."
update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# Upgrade pip
python3.11 -m pip install --upgrade pip setuptools wheel

# Clean up
rm -rf /var/lib/apt/lists/*

#=========================================
# CREATE APPLICATION DIRECTORY
#=========================================
log "📁 Creating application directory..."
mkdir -p "${APP_DIR}"
cd "${APP_DIR}"

#=========================================
# CLONE COMFYUI
#=========================================
if [ ! -d "${COMFYUI_DIR}" ]; then
    log "📥 Cloning ComfyUI from ${COMFYUI_REPO} (branch: ${COMFYUI_BRANCH})..."
    git clone --depth 1 --branch "${COMFYUI_BRANCH}" "${COMFYUI_REPO}" ComfyUI \
        || error "Failed to clone ComfyUI"
else
    log "⏭️  ComfyUI already exists at ${COMFYUI_DIR}"
fi

cd "${COMFYUI_DIR}"

#=========================================
# INSTALL PYTORCH 2.1.2 (CUDA 12.1)
#=========================================
log "🔥 Installing PyTorch 2.1.2 with CUDA 12.1 support..."
pip install --no-cache-dir \
    torch==2.1.2+cu121 \
    torchvision==0.16.2+cu121 \
    torchaudio==2.1.2+cu121 \
    --index-url https://download.pytorch.org/whl/cu121 \
    || error "Failed to install PyTorch"

#=========================================
# INSTALL COMFYUI REQUIREMENTS
#=========================================
log "📦 Installing ComfyUI requirements..."
if [ -f requirements.txt ]; then
    pip install --no-cache-dir -r requirements.txt \
        || error "Failed to install ComfyUI requirements"
else
    log "⚠️  Warning: requirements.txt not found"
fi

#=========================================
# OPENCV VERSION LOCKING
#=========================================
log "🔒 Setting up OpenCV version constraints..."

# Create OpenCV constraints file
cat > /tmp/opencv-constraints.txt << 'EOF'
opencv-python==4.10.0.84
opencv-python-headless==4.10.0.84
opencv-contrib-python==4.10.0.84
opencv-contrib-python-headless==4.10.0.84
EOF

export PIP_CONSTRAINT=/tmp/opencv-constraints.txt

log "📦 Installing OpenCV 4.10.0.84 (locked version)..."

# Uninstall any existing OpenCV
pip uninstall -y opencv-python opencv-python-headless \
    opencv-contrib-python opencv-contrib-python-headless 2>/dev/null || true

# Install locked OpenCV versions
pip install --no-cache-dir \
    opencv-python==4.10.0.84 \
    opencv-python-headless==4.10.0.84 \
    opencv-contrib-python==4.10.0.84 \
    opencv-contrib-python-headless==4.10.0.84 \
    || error "Failed to install OpenCV"

#=========================================
# INSTALL FACENET (PuLID DEPENDENCY)
#=========================================
log "📦 Installing FaceNet PyTorch (PuLID dependency)..."
pip install --no-cache-dir facenet-pytorch==2.6.0 \
    || error "Failed to install FaceNet"

#=========================================
# PREPARE CUSTOM NODES DIRECTORY
#=========================================
log "📁 Creating custom_nodes directory..."
mkdir -p "${COMFYUI_DIR}/custom_nodes"
cd "${COMFYUI_DIR}/custom_nodes"

#=========================================
# CLONE CUSTOM NODES
#=========================================
log "🔌 Cloning custom nodes..."

# You need to provide your custom_nodes.txt content
# For now, I'll create a template that you can fill in

# Option 1: If you have custom_nodes.txt in your repo
if [ -f "${COMFYUI_DIR}/custom_nodes.txt" ]; then
    log "📋 Found custom_nodes.txt in repository"
    CUSTOM_NODES_FILE="${COMFYUI_DIR}/custom_nodes.txt"
else
    # Option 2: Create it from inline content (you need to provide the URLs)
    log "📋 Creating custom_nodes.txt..."
    cat > /tmp/custom_nodes.txt << 'EOF'
# Add your custom node repositories here, one per line
# Example:
# https://github.com/ltdrdata/ComfyUI-Manager.git
# https://github.com/Fannovel16/comfyui_controlnet_aux.git
# etc...
EOF
    CUSTOM_NODES_FILE="/tmp/custom_nodes.txt"
fi

# Clone each custom node
log "====== Cloning Custom Nodes ======"
while IFS= read -r raw_repo; do
    # Remove carriage returns and trailing whitespace
    repo="$(echo "$raw_repo" | tr -d '\r' | sed 's/[[:space:]]*$//')"
    
    # Skip empty lines
    [ -z "$repo" ] && continue
    
    # Skip comments
    echo "$repo" | grep -qE '^[[:space:]]*#' && continue
    
    # Special handling for ComfyUI Manager
    if echo "$repo" | grep -qi "comfyui-manager"; then
        log "📦 Cloning ComfyUI Manager..."
        git clone --depth 1 "$repo" comfyui-manager || log "⚠️  Failed to clone comfyui-manager"
        continue
    fi
    
    # Clone other repositories
    repo_name=$(basename "$repo" .git)
    log "📦 Cloning ${repo_name}..."
    git clone --depth 1 "$repo" "$repo_name" || log "⚠️  Failed to clone ${repo_name}"
    
done < "$CUSTOM_NODES_FILE"

#=========================================
# INSTALL PULID FLUX (FACENET)
#=========================================
log "🔌 Setting up PuLID Flux FaceNet..."

cd "${COMFYUI_DIR}/custom_nodes"

# Normalize folder name if it has .git extension
if [ -d "ComfyUI_PuLID_Flux_ll_FaceNet.git" ]; then
    log "🔧 Normalizing PuLID folder name..."
    mv ComfyUI_PuLID_Flux_ll_FaceNet.git ComfyUI_PuLID_Flux_ll_FaceNet
fi

# Clone if not already present
if [ ! -d "ComfyUI_PuLID_Flux_ll_FaceNet" ]; then
    log "📦 Cloning PuLID Flux FaceNet..."
    git clone --depth 1 \
        https://github.com/KY-2000/ComfyUI_PuLID_Flux_ll_FaceNet \
        ComfyUI_PuLID_Flux_ll_FaceNet \
        || log "⚠️  Failed to clone PuLID Flux"
fi

# Install PuLID requirements
if [ -f "ComfyUI_PuLID_Flux_ll_FaceNet/requirements.txt" ]; then
    log "📦 Installing PuLID requirements..."
    pip install --no-cache-dir -r \
        ComfyUI_PuLID_Flux_ll_FaceNet/requirements.txt || log "⚠️  Some PuLID dependencies failed"
fi

# Install optional InsightFace
log "📦 Installing InsightFace (optional)..."
pip install --no-cache-dir \
    insightface==0.7.3 \
    onnxruntime \
    onnxruntime-gpu \
    || log "⚠️  InsightFace installation had issues (non-critical)"

#=========================================
# INSTALL ALL CUSTOM NODE REQUIREMENTS
#=========================================
log "📦 Installing requirements for all custom nodes..."

cd "${COMFYUI_DIR}/custom_nodes"

for node_dir in */; do
    if [ -f "${node_dir}requirements.txt" ]; then
        log "📦 Installing requirements for ${node_dir}..."
        pip install --no-cache-dir -r "${node_dir}requirements.txt" \
            || log "⚠️  Some dependencies failed for ${node_dir} (continuing...)"
    fi
done

#=========================================
# FINAL OPENCV RE-LOCK
#=========================================
log "🔒 Re-locking OpenCV versions (final)..."

cd "${COMFYUI_DIR}"

# Uninstall any OpenCV that might have been installed by dependencies
pip uninstall -y opencv-python opencv-python-headless \
    opencv-contrib-python opencv-contrib-python-headless 2>/dev/null || true

# Force reinstall exact versions
pip install --no-cache-dir --force-reinstall --no-deps \
    opencv-python==4.10.0.84 \
    opencv-python-headless==4.10.0.84 \
    opencv-contrib-python==4.10.0.84 \
    opencv-contrib-python-headless==4.10.0.84 \
    || error "Failed to lock OpenCV versions"

#=========================================
# VERIFICATION
#=========================================
log "🧪 Verifying installation..."

python3.11 << 'PYVERIFY'
import sys
print("\n" + "="*60)
print("Installation Verification")
print("="*60)

# Torch verification
try:
    import torch
    print(f"✅ PyTorch: {torch.__version__}")
    print(f"✅ CUDA Available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"✅ CUDA Version: {torch.version.cuda}")
        print(f"✅ GPU: {torch.cuda.get_device_name(0)}")
        print(f"✅ GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
except Exception as e:
    print(f"❌ PyTorch Error: {e}")
    sys.exit(1)

# OpenCV verification
try:
    import cv2
    print(f"✅ OpenCV: {cv2.__version__}")
    if cv2.__version__ != "4.10.0.84":
        print(f"⚠️  Warning: OpenCV version mismatch (expected 4.10.0.84)")
except Exception as e:
    print(f"❌ OpenCV Error: {e}")
    sys.exit(1)

# FaceNet verification
try:
    from facenet_pytorch import MTCNN
    print(f"✅ FaceNet: Loaded successfully")
except Exception as e:
    print(f"❌ FaceNet Error: {e}")
    sys.exit(1)

# GPU computation test
try:
    x = torch.randn(1000, 1000, device='cuda')
    y = x @ x.T
    torch.cuda.synchronize()
    print(f"✅ GPU Computation: PASSED")
except Exception as e:
    print(f"❌ GPU Test Error: {e}")
    sys.exit(1)

print("="*60 + "\n")
PYVERIFY

[ $? -eq 0 ] || error "Verification failed"

#=========================================
# CREATE STARTUP SCRIPT
#=========================================
log "📝 Creating startup script..."

cat > /workspace/start_comfyui.sh << 'EOF'
#!/bin/bash

# Environment setup
export DEBIAN_FRONTEND=noninteractive
export PYTHONUNBUFFERED=1
export TZ=UTC

# CUDA optimizations for RTX 4090
export CUDA_FORCE_PTX_JIT=1
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Navigate to ComfyUI
cd /workspace/app/ComfyUI

# Start ComfyUI
echo "🚀 Starting ComfyUI AI Photobooth..."
echo "🌐 Access at: http://YOUR_VAST_IP:8188"
echo ""

python /workspace/app/ComfyUI/main.py --listen 0.0.0.0 --port 8188

EOF

chmod +x /workspace/start_comfyui.sh

#=========================================
# CREATE ENTRYPOINT SCRIPT
#=========================================
log "📝 Creating entrypoint script..."

cat > /workspace/entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "========================================="
echo "ComfyUI AI Photobooth"
echo "========================================="
echo ""

# Display system info
echo "📊 System Information:"
python3.11 -c "
import torch
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
    print(f'CUDA: {torch.version.cuda}')
    print(f'PyTorch: {torch.__version__}')
else:
    print('⚠️  No GPU detected')
"
echo ""

# Execute the command passed to docker run / vast.ai
exec "$@"
EOF

chmod +x /workspace/entrypoint.sh

#=========================================
# CLEANUP
#=========================================
log "🧹 Cleaning up..."

# Clear pip cache
pip cache purge

# Remove temporary files
rm -f /tmp/custom_nodes.txt /tmp/opencv-constraints.txt

#=========================================
# COMPLETION MESSAGE
#=========================================
log "========================================="
log "✅ Provisioning Complete!"
log "========================================="
log ""
log "📁 Installation:"
log "   ComfyUI: ${COMFYUI_DIR}"
log "   Logs: ${LOG_FILE}"
log ""
log "🚀 To start ComfyUI:"
log "   /workspace/start_comfyui.sh"
log ""
log "🌐 Access ComfyUI at:"
log "   http://YOUR_VAST_IP:8188"
log ""
log "📊 Installed Versions:"
python3.11 -c "
import torch, cv2
print(f'   PyTorch: {torch.__version__}')
print(f'   CUDA: {torch.version.cuda}')
print(f'   OpenCV: {cv2.__version__}')
if torch.cuda.is_available():
    print(f'   GPU: {torch.cuda.get_device_name(0)}')
"
log ""
log "========================================="
