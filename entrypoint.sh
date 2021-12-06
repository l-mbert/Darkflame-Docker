#!/bin/bash

mysqld_safe # & (sleep 10 && /DarkflameServer/build/MasterServer)
exec "$@"
