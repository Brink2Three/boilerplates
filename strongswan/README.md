## Strongswan public example configurations ##

Strongswan is a building block, often used to build fast, secure VPN tunnels using the standard IKEv2/IPsec protocols. 
The docs here will serve as examples for how to install and configure Strongswan on Ubuntu 22.04 and 24.04 LTS versions. 

See install.md for the install process on ubuntu, and check the /configs folder for example configurations (they are labeled depending on how you plan to use them.)

The strongswan tools are completely free and allow you to connect to services like Active Directory, FreeRadius, and even Oauth2 when used with the [vpn-webauth](https://github.com/m-barthelemy/vpn-webauth) plugin.

The majority of my configurations use a shared certificate for Auth step 1 (instead of a preshared key) and Active Directory Username/Password combos for step 2. A Step 3 (MFA) can be added using vpn-webauth as mentioned above. 

Other docs will also be added in the future for configuring Active Directory to authenticate VPN users for strongswan, but are not completed at this time. 
