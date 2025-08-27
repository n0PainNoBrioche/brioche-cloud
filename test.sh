#!/bin/bash

# -------------------------------
# 1️⃣ Delete all stuck volsync jobs
# -------------------------------
echo "🗑️ Deleting all stuck volsync jobs..."
kubectl get jobs -A --field-selector=status.successful!=1 -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers \
| grep volsync \
| while read ns job; do
    echo "Deleting job $job in namespace $ns"
    kubectl delete job $job -n $ns --cascade=foreground
done

# -------------------------------
# 2️⃣ Delete all pods from deleted jobs
# -------------------------------
echo "🗑️ Deleting pods belonging to deleted volsync jobs..."
kubectl get pods -A -o json | jq -r '.items[] | select(.metadata.ownerReferences[]?.kind=="Job") | "\(.metadata.namespace) \(.metadata.name)"' \
| grep volsync \
| while read ns pod; do
    echo "Deleting pod $pod from namespace $ns"
    kubectl delete pod $pod -n $ns --force --grace-period=0
done

# -------------------------------
# 3️⃣ Delete all volsync Longhorn snapshots
# -------------------------------
echo "🗑️ Deleting all volsync snapshots..."
kubectl get snapshots.longhorn.io -n longhorn-system -o name | grep volsync \
| while read snap; do
    echo "Deleting snapshot $snap"
    kubectl delete $snap -n longhorn-system --force --grace-period=0
done

# -------------------------------
# 4️⃣ Delete all volsync Longhorn volumes
# -------------------------------
echo "🗑️ Deleting all volsync volumes..."
kubectl get volumes.longhorn.io -n longhorn-system -o name | grep volsync \
| while read vol; do
    echo "Deleting volume $vol"
    kubectl delete $vol -n longhorn-system --force --grace-period=0
done
