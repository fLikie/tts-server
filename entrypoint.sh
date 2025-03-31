#!/bin/bash

echo "Pulling latest changes from Git..."
git pull origin main || echo "Failed to pull or not a git repo."

echo "Building Go server..."
go build -o server main.go || exit 1

echo "Starting server..."
./server
