#!/bin/bash
# Build custom Factorio Docker image with latest version

set -e

IMAGE_NAME="factorio-custom"
IMAGE_TAG="${1:-latest}"

echo "Building Factorio Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "This will download the latest stable Factorio version automatically"
echo ""

# Build the image
docker build \
  --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
  --tag "${IMAGE_NAME}:latest" \
  --build-arg VERSION="" \
  -f Dockerfile \
  .

echo ""
echo "✅ Build complete!"
echo ""
echo "To use this image, update truenas_custom_app.yaml:"
echo "  image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Or push to a registry:"
echo "  docker tag ${IMAGE_NAME}:${IMAGE_TAG} your-registry/${IMAGE_NAME}:${IMAGE_TAG}"
echo "  docker push your-registry/${IMAGE_NAME}:${IMAGE_TAG}"
