#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if helm is installed
if ! command -v helm &> /dev/null
then
    echo "Helm could not be found. Please install Helm."
    exit 1
fi

# Create argocd namespace if it doesn't exist
if ! kubectl get namespace argocd &> /dev/null; then
    echo "Creating argocd namespace..."
    if ! kubectl create namespace argocd; then
        echo "Failed to create argocd namespace."
        exit 1
    fi
    echo "Namespace argocd created successfully."
else
    echo "Namespace argocd already exists."
fi

# Check if Argo CD is already installed by looking for the argocd-server deployment
if kubectl get deployment argocd-server -n argocd &> /dev/null; then
    echo "Argo CD is already installed. Skipping installation."
else
    # Add the Argo Helm repository
    if ! helm repo add argo https://argoproj.github.io/argo-helm; then
        echo "Failed to add Argo Helm repository."
        exit 1
    fi

    # Update Helm repositories
    if ! helm repo update; then
        echo "Failed to update Helm repositories."
        exit 1
    fi

    # Install Argo CD using Helm
    echo "Installing Argo CD..."
    if ! helm upgrade --install argocd argo/argo-cd -n argocd; then
        echo "Argo CD installation failed."
        exit 1
    fi
    echo "Argo CD installed successfully."
fi

# Wait for the Argo CD server to be ready
if ! kubectl wait --for=condition=available --timeout=60s deployment/argocd-server -n argocd; then
    echo "Argo CD server is not ready."
    exit 1
fi
echo "Argo CD server is ready." 

# create the cluster apps app set

if ! kubectl apply -f cluster-pre-req-appset.yaml; then
    echo "Failed to create the clusterapps app set."
    exit 1
fi
echo "Clusterapps app set created successfully."

# Wait for the cluster apps app set to be ready by checking if all argo applications are created
kubectl get applications -n argocd
if ! kubectl wait --for=condition=available --timeout=60s applicationset/clusterapps -n argocd; then
    echo "Cluster apps app set is not ready."
    exit 1
fi
echo "Cluster apps app set is ready."

