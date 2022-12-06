#!/bin/bash
# Docker entrypoint script.

mix ecto.migrate
exec mix phx.server