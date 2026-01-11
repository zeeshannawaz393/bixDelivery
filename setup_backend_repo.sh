#!/bin/bash

# Backend Repository Setup Script
# This script helps you set up a separate backend repository

echo "🚀 Courier MVP Backend Repository Setup"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the current directory
CURRENT_DIR=$(pwd)
PARENT_DIR=$(dirname "$CURRENT_DIR")
BACKEND_REPO_NAME="courier-mvp-backend"
BACKEND_REPO_PATH="$PARENT_DIR/$BACKEND_REPO_NAME"

echo "📁 Current project: $CURRENT_DIR"
echo "📁 Backend repo will be created at: $BACKEND_REPO_PATH"
echo ""

# Check if backend repo directory already exists
if [ -d "$BACKEND_REPO_PATH" ]; then
    echo -e "${YELLOW}⚠️  Directory $BACKEND_REPO_PATH already exists!${NC}"
    read -p "Do you want to remove it and start fresh? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$BACKEND_REPO_PATH"
        echo -e "${GREEN}✅ Removed existing directory${NC}"
    else
        echo -e "${RED}❌ Setup cancelled${NC}"
        exit 1
    fi
fi

# Create backend repo directory
echo "📦 Creating backend repository directory..."
mkdir -p "$BACKEND_REPO_PATH"
cd "$BACKEND_REPO_PATH"

# Copy backend folder
if [ -d "$CURRENT_DIR/backend" ]; then
    echo "📋 Copying backend folder..."
    cp -r "$CURRENT_DIR/backend" .
    echo -e "${GREEN}✅ Backend folder copied${NC}"
else
    echo -e "${RED}❌ Error: backend folder not found in $CURRENT_DIR${NC}"
    exit 1
fi

# Copy functions folder
if [ -d "$CURRENT_DIR/functions" ]; then
    echo "📋 Copying functions folder..."
    cp -r "$CURRENT_DIR/functions" .
    echo -e "${GREEN}✅ Functions folder copied${NC}"
else
    echo -e "${YELLOW}⚠️  Functions folder not found, skipping...${NC}"
fi

# Create .gitignore
echo "📝 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Firebase Admin SDK Keys (CRITICAL: Never commit these!)
*.json
!package.json
!firebase.json
!tsconfig.json
!*.config.json

# Environment variables
.env
.env.local
.env.*.local
.env.production
.env.development

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
firebase-debug.log

# OS files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
*.sublime-project
*.sublime-workspace

# Build outputs
dist/
build/
*.tsbuildinfo
lib/

# Firebase
.firebase/
.firebaserc
firebase-debug.log
.firebaserc.local

# Testing
coverage/
.nyc_output/

# Temporary files
tmp/
temp/
*.tmp
EOF
echo -e "${GREEN}✅ .gitignore created${NC}"

# Initialize git
echo "🔧 Initializing git repository..."
git init
echo -e "${GREEN}✅ Git initialized${NC}"

# Ask for GitHub repository URL
echo ""
echo -e "${YELLOW}📡 GitHub Repository Setup${NC}"
echo "If you haven't created a GitHub repository yet:"
echo "  1. Go to https://github.com/new"
echo "  2. Create a repository named: $BACKEND_REPO_NAME"
echo "  3. DO NOT initialize with README, .gitignore, or license"
echo ""
read -p "Enter your GitHub repository URL (or press Enter to skip): " GITHUB_URL

if [ ! -z "$GITHUB_URL" ]; then
    git remote add origin "$GITHUB_URL"
    echo -e "${GREEN}✅ Remote added: $GITHUB_URL${NC}"
else
    echo -e "${YELLOW}⚠️  No remote added. You can add it later with:${NC}"
    echo "   git remote add origin <your-github-url>"
fi

# Create initial commit
echo ""
echo "📝 Creating initial commit..."
git add .
git commit -m "Initial commit: Backend services (Express + Cloud Functions)"
echo -e "${GREEN}✅ Initial commit created${NC}"

# Summary
echo ""
echo "========================================"
echo -e "${GREEN}✅ Backend repository setup complete!${NC}"
echo "========================================"
echo ""
echo "📁 Repository location: $BACKEND_REPO_PATH"
echo ""
echo "📋 Next steps:"
echo "  1. cd $BACKEND_REPO_PATH"
if [ -z "$GITHUB_URL" ]; then
    echo "  2. Add GitHub remote: git remote add origin <your-github-url>"
    echo "  3. Push to GitHub: git push -u origin main"
else
    echo "  2. Push to GitHub: git push -u origin main"
fi
echo "  4. Add Firebase Admin SDK keys (download from Firebase Console)"
echo "  5. Install dependencies:"
echo "     - cd backend && npm install"
echo "     - cd ../functions && npm install"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Never commit Firebase Admin SDK JSON files!${NC}"
echo "   They are already in .gitignore"
echo ""

