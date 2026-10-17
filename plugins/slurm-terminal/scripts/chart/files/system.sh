#!/bin/sh
set -e

# This container is only an SSH client. There is no Slurm installed here and no
# Slurm credential mounted — sbatch/srun/squeue all run on the login node at the
# other end of the connection, which already holds slurm.conf and the auth key.
#
# The user authenticates to the login node as themselves (SSSD/LDAP on the login
# node decides who they are), so one workload template serves every user: Kuiper
# renders it per launch with USER set to whoever launched it.

cd /usr/src/app

SLURM_LOGIN_HOST="${SLURM_LOGIN_SERVICE}.${SLURM_NAMESPACE}.svc.cluster.local"

# Base path for wetty (matches the ingress/nginx path)
WETTY_BASE="/slurm/$WORKSTATION_NAME"

echo "Connecting terminal to Slurm login node ${SLURM_LOGIN_HOST}:${SLURM_LOGIN_PORT} as ${USER}"

# --force-ssh is required: the container runs as root, and without it wetty would
# spawn a local login shell instead of connecting out over SSH.
# --ssh-auth password makes wetty prompt for the user's own directory password.
LANG=C.UTF-8 LC_ALL=C.UTF-8 COLORTERM=truecolor NODE_ENV=production \
  node . -b "$WETTY_BASE" --allow-iframe \
  -p 3000 \
  --title "Slurm — $WORKSTATION_NAME" \
  --force-ssh \
  --ssh-host "$SLURM_LOGIN_HOST" \
  --ssh-port "$SLURM_LOGIN_PORT" \
  --ssh-user "$USER" \
  --ssh-auth password
