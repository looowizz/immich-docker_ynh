domain_regex=${domain//[.]/\\.} # Replace "." with "\." for use in regex in fail2ban config
failregex="^<HOST>.*\"(POST).*(401).*($domain_regex).*$"

myynh_docker_pull() {
	cd $install_dir
	docker compose pull
}

myynh_docker_up() {
	cd $install_dir
	docker compose up -d
}

# Backs up the database (NOTE: Immich must be running for this to work)
myynh_backup_db() {
	cd $install_dir
	mkdir "$install_dir/db_backup" -p
	docker exec -t immich_postgres pg_dumpall --clean --if-exists --username=postgres | gzip > "db_backup/dump.sql.gz"
}

myynh_restore_db() {
	cd $install_dir
	docker compose down -v  # CAUTION! Deletes all Immich data to start from scratch
	## Uncomment the next line and replace DB_DATA_LOCATION with your Postgres path to permanently reset the Postgres database
	rm -rf $install_dir/db # CAUTION! Deletes all Immich data to start from scratch
	docker compose pull             # Update to latest version of Immich (if desired)
	docker compose create           # Create Docker containers for Immich apps without running them
	docker start immich_postgres    # Start Postgres server
	sleep 10                        # Wait for Postgres server to start up
	# Check the database user if you deviated from the default
	gunzip < "$install_dir/db_backup/dump.sql.gz" \
	| sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
	| docker exec -i immich_postgres psql --username=postgres  # Restore Backup
	ynh_secure_remove --file="$install_dir/db_backup"
}
