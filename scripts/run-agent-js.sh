#!/bin/bash

# Run the TypeScript agent in development mode
cd "$(dirname "$0")/.." || exit 1

# Check if node_modules exists
if [ ! -d "agent-js/node_modules" ]; then
    echo "Installing agent-js dependencies..."
    cd agent-js && pnpm install && cd ..
fi

cd agent-js && pnpm run start

