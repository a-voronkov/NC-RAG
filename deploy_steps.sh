#!/bin/bash

echo "=== NC-RAG Deployment Steps ==="
echo "Server: $SSH_SERVER"
echo "User: $SSH_USER"
echo ""

echo "Step 1: Connect to server"
echo "Command: ssh $SSH_USER@$SSH_SERVER"
echo ""

echo "Step 2: Navigate to project directory"
echo "Command: cd /srv/docker/nc-rag"
echo ""

echo "Step 3: Check current status"
echo "Commands:"
echo "  pwd"
echo "  git status"
echo "  docker compose ps"
echo ""

echo "Step 4: Pull latest changes"
echo "Command: git pull origin main"
echo ""

echo "Step 5: Update environment"
echo "Commands:"
echo "  cp .env.example .env"
echo "  nano .env  # Edit with production values"
echo ""

echo "Step 6: Deploy services"
echo "Commands:"
echo "  docker compose down"
echo "  docker compose up -d --build"
echo ""

echo "Step 7: Verify deployment"
echo "Commands:"
echo "  docker compose ps"
echo "  docker compose logs worker --tail=10"
echo "  docker compose logs redis --tail=5"
echo ""

echo "Step 8: Test integration"
echo "Command: ./scripts/test-phase4.sh"
echo ""

echo "=== Manual SSH Session Required ==="
echo "Please run: ssh $SSH_USER@$SSH_SERVER"
echo "Then execute the commands above step by step."