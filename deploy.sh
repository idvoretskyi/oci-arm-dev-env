#!/bin/bash
set -e

case "${1:-deploy}" in
  deploy)
    tofu init
    tofu apply
    echo
    echo "SSH: $(tofu output -raw ssh)"
    echo "Wait 5-10 minutes for cluster setup"
    ;;
  destroy)
    tofu destroy
    ;;
  *)
    echo "Usage: $0 [deploy|destroy]"
    exit 1
    ;;
esac
