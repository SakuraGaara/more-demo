#!/bin/sh

mysql -A --prompt='[\D] MySQL-\v \u@\h:\p/\d \c > ' epaydb_beta
