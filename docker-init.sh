#!/bin/bash -e

# Check if the dogecoin conf exists already
if [ ! -f /root/.dogecoin/dogecoin.conf ]; then
  echo "Empty dogecoin directory found, will be initialized with this first run."
  # If we've hit this block of code then it's fair to assume dogecoin has never
  # run before. Syncing the dogecoin blockchain can take a very long time. If
  # the user wants we can start dogecoin with a bootstrap file to speed things up.

  # Does user want us to sync from bootstrap?
  if [ "$SYNC_FROM_BOOTSTRAP_IF_UNINITIALIZED" = true ]; then
    # First start dogecoin to set up initial files.
    dogecoind -printtoconsole -shrinkdebugfile &
    DOGECOIN_PID=$!

    # Wait for dogecoin to start and run for a bit, then stop it
    sleep 10

    # Stop our dogecoin process now that it has built our basic file structure
    kill $DOGECOIN_PID

    # Download bootstrap.dat to speed up node sync
    curl -o ~/.dogecoin/bootstrap.dat https://bootstrap.sochain.com/bootstrap.dat
  fi
else
  echo "Dogecoin configuration discovered."
  # If we got to this block then the ~/.dogecoin directory already exists. Clear
  # out the old bootstrap file if it exists, then run dogecoin.
  if [ -f ~/.dogecoin/bootstrap.dat.old ]; then
    rm ~/.dogecoin/bootstrap.dat.old
  fi
fi

# Start dogecoind daemon
echo "Starting dogecoind..."
dogecoind -printtoconsole -shrinkdebugfile -onlynet=ipv4 -onlynet=onion
