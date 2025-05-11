#!/usr/bin/env bash

set -euo pipefail

# === Step 1: Build the app with Gleam ===
echo "Building app with Gleam..."
gleam run -m lustre/dev build app --minify

# === Step 2: Copy output to 'dist' directory ===
echo "✅ Creating dist directory and copying files..."
mkdir -p dist
cp index.html dist/index.html
cp -r priv dist/priv
cp netlify.toml dist/netlify.toml

# === Step 3: Update path in index.html to use minified app ===
echo "✅ Updating app path in dist/index.html..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's|priv/static/app\.mjs|priv/static/app.min.mjs|' dist/index.html
else
    sed -i 's|priv/static/app\.mjs|priv/static/app.min.mjs|' dist/index.html
fi

echo "✅ Build and preparation complete."
