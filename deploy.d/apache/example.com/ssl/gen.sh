#!/bin/bash


openssl req -new -newkey rsa:4096 -nodes -keyout private.key -out request.csr
