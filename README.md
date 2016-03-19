# LetsEncrypt Cloudflare DNS Hook (Ruby)

The following dns hook can be used to make LetsEncrypt compatible with Cloudflare's DNS system

## Installation

The installation has been tested with [acmetool](https://github.com/hlandau/acme).

```
git clone https://github.com/charlesportwoodii/letsencrypt-cloudflare-hook-ruby hooks/cloudflare
cd hooks/cloudflare
bundle install # --path bundler
chmod a+x hooks/cloudflare/cloudflare.rb
ln -s hooks/cloudflare/cloudflare.rb /usr/libexec/acme/hooks/cloudflare.rb
cp hooks/cloudflare/cloudflare.yml /var/lib/acme/cloudflare.yml
```

After installing the package, edit ```/var/lib/acme/cloudflare.yml``` with your Cloudflare email address and API key

# License

MIT License. See [LICENSE.md](LICENSE.md)