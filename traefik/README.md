## Traefik config

My traefik config is a bit special for a few reasons:
1. Most of the services I forward through it are *not* in docker, so it has to use local IP addresses (10.0.0.4, 172.16.0,65, etc.)
2. I **ONLY** want to expose services over HTTPS/SSL, including internally.
3. I wanted to configure traefik exclusively from config files, not docker labels. 

I may attempt mixed configs in the future, but setting traefik to watch a folder and editing/adding yml files allowed traefik to dynamically create and destroy services. So it worked quite well. 

For this config, my docker-compose.yml file is set up as a docker stack in the portainer webUI. The stack for traefik is as follows:

```
---
volumes:
  traefik-ssl-certs:
    driver: local

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    ports:
      - 80:80
      - 443:443
    volumes:
      - /etc/traefik:/etc/traefik
      - traefik-ssl-certs:/ssl-certs
      - /var/run/docker.sock:/var/run/docker.sock:ro
#### -- (Optional) When using Cloudflare as Cert Resolver. This can be moved to a .env file if your dockerfile storage is insecure.
    environment:
      - CLOUDFLARE_EMAIL=email@domain.com
      - CLOUDFLARE_API_KEY=API KEY HERE
    restart: unless-stopped
```

On the docker host, the root of this traefik folder lives as /etc/traefik. So the file folders line up with the users and certs folders as listed in the traefik.yml file. 

# NOTES

- The localroutes are for services that are not forwarded to the internet. These only add SSL on top of the service, and I have a DNS entry of `address=/.internal.domainname.com/internal-ip-of-traefik` in my internal dns (pihole) which maps anything.internal.domainname.com to the ip of traefik. This makes things like proxmox, portainer, and plex have an internal address with SSL. 

- You might look at this and go, "wow, that's a lot of middlewares just for the Pihole webUI..." **IT IS...** I don't know why it was so fussy, but to get pihole's webUI to co-operate through traefik, I had to add ALL OF THAT for it to work. 
  - Reference for this: https://community.traefik.io/t/external-pihole-behind-traefik-redirect-admin/17383/9 