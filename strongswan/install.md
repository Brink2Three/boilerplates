# INSTALL AND SETUP STRONGSWAN: (In progress) 
## Stage 0: Hardware suggestions
This setup is unique as we have to configure the VM with some unique settings. 
Here are the suggested hardware requirements:
For max speed vs average users, use whichever is lower at average usage. Varies by CPU generation.
| Max speed/ avg. Users | Cores (vCPUs)     | RAM | Expected Cloud cost |
| --------------------- | ----              | --- | -------------   |
| 750 Mbps / 35 Users   | 1vcpu (0.5 core)  | 2GB | ~ $26/mo        |
| 1.4 Gbps / 60 Users   | 2vcpus (1 core)   | 2GB | ~ $53/mo        |
| 2.2 Gbps / 100 Users  | 4vcpus (2 cores)  | 4GB | ~ $74/mo        |
| 3.0 Gbps / 180 Users  | 8vcpus (4 cores)  | 8GB | ~ $146/mo       |

IPSec has a fixed amount of CPU and memory required to keep the tunnel open. The estimate above is based on monitoring data with 50-200 users.

Suggestions based on table here. May need adjustment on a case by case basis.  https://gcpinstances.doit-intl.com/

Total speed DOES NOT equal single user speed. IPsec linux kernel tunnels max out around 350-400 Mbps per tunnel per core, though different protocols and encryption will see varying performance.

Also ensure to update the OS after first setup. The default strongswan package is out of date. And vulnerable to a [buffer overflow attack](https://www.cvedetails.com/cve/CVE-2023-41913/)

> Sudo apt update

> Sudo apt upgrade

## Stage 1 (Optional): Dynamic DNS address using ddns.net

Go to ddns.net and create an account. Pick a free domain name and enter the subdomain you want to use. This will be known from here on as `DDNSADDR.ddns.net`. Replace that with your domain name when seen. 

Install prerequisites and move to src directory. 

> apt install make gcc -y

> cd /usr/local/src/

Copy the noIP linux agent to the current directory. Unzip the tar ball. 

(This directory may change, reference https://www.noip.com/download?page=linux to confirm newest version.)

> wget http://www.noip.com/client/linux/noip-duc-linux.tar.gz

> tar xf noip-duc-linux.tar.gz

Enter the unzipped noip folder and use GCC to build the binaries. 

> cd noip-2.1.9-1/

> make install

Configure noIP with the credentials for your account. Select the domain and refresh timer interval.

```
Please enter the login/email string for no-ip.com: example@domain.com
Please enter the password for user 'example@domain.com': ******
Only one host [noipdomain.ddns.net] is registered to this account.
Please enter an update interval:[30]
Do you wish to run something at successful update?[N] (y/N) N
```

Depending on the install, noIP may automatically copy the config file to etc/no-ip2.conf. If it does not, run: 

> mv /tmp/no-ip2.conf /usr/local/etc/no-ip2.conf

Since we want this to run automatically when the server reboots, we’ll set it up in systemd.

> sudo nano /etc/systemd/system/noip2.service

Paste the following into the blank file. Once entered, save and exit by hitting ctrl + x, y, enter. 

```
[Unit]
Description=noip2 service

[Service]
Type=forking
ExecStart=/usr/local/bin/noip2
Restart=always

[Install]
WantedBy=default.target
```
Once saved, reload systemd to make it register the entry, then start, enable and check the status.

> sudo systemctl daemon-reload

> sudo systemctl start noip2

> sudo systemctl enable noip2

> sudo systemctl status noip2

The output should include a “Active (Running)” status. If it does, this step is complete. 


## Stage 2: Certificates, Strongswan, and IPSec setup 
Start by installing Strongswan and it’s dependencies.

> sudo apt install strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins libstrongswan-extra-plugins libtss2-tcti-tabrmd0 -y 

Create a temporary directory for the CA certificates, Server certificate, and private keys for both. 

> mkdir -p ~/pki/{cacerts,certs,private}

> chmod 700 ~/pki

Generate the CA (Certificate Authority) key, then use that key to create the CA Certificate. (Lifetime is in days. Adjust as needed)

> pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/ca-key.pem

> pki --self --ca --lifetime 3650 --in ~/pki/private/ca-key.pem --type rsa --dn "CN=VPN root CA" --flag serverAuth --outform pem > ~/pki/cacerts/ca-cert.pem

Then we generate the server key and server certificate, using our earlier CA as the Root auth.

> pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/server-key.pem

```
pki --pub --in ~/pki/private/server-key.pem --type rsa \
    | pki --issue --lifetime 1825 \
        --cacert ~/pki/cacerts/ca-cert.pem \
        --cakey ~/pki/private/ca-key.pem \
        --dn "CN=DDNSADDR.ddns.net" --san DDNSADDR.ddns.net \
        --flag serverAuth --outform pem \
    >  ~/pki/certs/server-cert.pem
```
Finally, copy the certificates and keys to ipsec. IPsec will use these keys and certificates to verify users before prompting for credentials.

> sudo cp -r ~/pki/* /etc/ipsec.d/


## Stage 3: IKEv2 configuration

### NOTE: This setup is a split tunnel deployment, meaning this will not affect the user’s local network access, and internet connections will derrive from the client's network.

Create a backup of the default ipsec.conf file, then open it to start editing. 
> sudo mv /etc/ipsec.conf{,.original}

Select EITHER the Radius/NPS/AD auth option, or the Local Users option. 


### RADIUS/NPS/AD IPSec configuration

The following config is the updated configuration for use with Radius. You will also need to update strongswan.conf with access to the radius server.
If using active directory, you will also need to configure

> sudo nano /etc/ipsec.conf

Enter the content in configs/Radius-or-Active-Directory/ipsec.conf

###  RADIUS/NPS/AD Authentication configuration 

> sudo nano /etc/strongswan.conf

Paste the content from configs/Radius-or-Active-Directory/strongswan.conf


### Local Account Authentication (Suggested for testing before configuring NPS/AD)

If using local accounts to access the VPN server, see the config below:

> sudo nano /etc/ipsec.conf

Enter the content in configs/Local-Users/ipsec.conf


### LOCAL USER AUTHENTICATION

> sudo nano /etc/strongswan.conf

configs/Local-Users/strongswan.conf

To add local accounts that will authenticate with EAP (method shown in ipsec.conf for local accounts above), we have to add accounts to ipsec.secrets.

To add local accounts. Don’t forget to save this. This file also exists in the configs/Local-Users folder.
> sudo nano /etc/ipsec.secrets

```
: RSA "server-key.pem"
exampleuser : EAP "examplepassword"
exampleuser1 : EAP "examplepassword1"
exampleuser2 : EAP "examplepassword2"
```

## Stage 4: Server Firewall

Since this device is going to be facing the public internet, we want to lock it down as much as possible. We’re only going to leave port 500, and 4500 open externally, as well as setting up routing to forward VPN traffic to the internal network.

Starting with Allowing SSH to ensure we don’t lock ourselves out, then allow the ports we need for IPsec. 

Ensure to only open SSH for locally networked devices. 

> sudo ufw allow from [LAN SUBNET] to any port 22

> sudo ufw allow 500,4500/udp

> sudo ufw enable

> sudo ufw status

Next, list the interfaces on the VM and save the interface name. In the example below I show the command and the response from the server, with the interface name being `eth0`. 

> ip route show default
```
default via 10.10.0.1 dev eth0 proto dhcp src 10.10.0.69 metric 100
```

Set the pre-firewall rules as below. This includes the file you change and the entries to make. Be aware of the existing filter rules. Place the first segment above them, and the second below. Make sure to change the subnet to match the rest of your configuration.

### NOTE: For the *mangle rule, adjust this to match the MTU of the local network your strongswan server is on. 
This usually defaults to 1500, but check your network settings to be sure. 

To print the MTU of your current interface here's a command and the response on my example machine. Use the numbered item with the same interface name as listed in `ip route` above:
> ip a | grep -i MTU

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
```
Now on to the firewall rules. Again place the `*nat` and `*mangle` classes **BEFORE** existing rules, and the `ufw-before-forward` rules **AFTER** the existing rules.

> sudo nano /etc/ufw/before.rules

```
*nat
-A POSTROUTING -s 10.100.0.0/23 -o eth0 -m policy --pol ipsec --dir out -j ACCEPT
-A POSTROUTING -s 10.100.0.0/23 -o eth0 -j MASQUERADE
COMMIT

*mangle
-A FORWARD --match policy --pol ipsec --dir in -s 10.100.0.0/23 -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1501:1536 -j TCPMSS --set-mss 1500
COMMIT

**EXISTING FILTER RULES**
**EXISTING FILTER RULES**
**EXISTING FILTER RULES**

** Place just below other `ufw-before-forward` rules**
-A ufw-before-forward --match policy --pol ipsec --dir in --proto esp -s 10.100.0.0/23 -j ACCEPT
-A ufw-before-forward --match policy --pol ipsec --dir out --proto esp -d 10.100.0.0/23 -j ACCEPT

**THESE SHOULD BE ABOVE ufw-before-input rules**
```

Save and exit this file. 

Next, open the system routing rules and paste the following at the end of the file. File path and changes formatted the same as above. 

> sudo nano /etc/ufw/sysctl.conf

```
**Existing Sys Rules**

net/ipv4/ip_forward=1
net/ipv4/conf/all/accept_redirects=0
net/ipv4/conf/all/send_redirects=0
net/ipv4/ip_no_pmtu_disc=1
```

Save and exit the file. 

Finally, we can reload the firewall and put our changes into effect. 

> sudo ufw disable

> sudo ufw enable

If you get errors stating `ERROR: problem running ufw-init`, you messed up the rule order.

## Stage 5: Testing
If all changes were made correctly, we are now ready to test the VPN. 

Setup is exactly the same as the digital ocean article referenced below, so this is directly copy-pasted. 

Copy the CA certificate you created and install it on your client device(s) that will connect to the VPN. The easiest way to do this is to log into your server and output the contents of the certificate file. Output is below the command:

> cat /etc/ipsec.d/cacerts/ca-cert.pem

```
-----BEGIN CERTIFICATE-----

. . .

-----END CERTIFICATE-----
```

Copy the entire certificate, including -----BEGIN CERTIFICATE----- and -----END CERTIFICATE----- to a txt file on your computer, and save it as something like “ca-cert.pem”.

On windows, paste the following into an Admin powershell window:
```
Import-Certificate `
    -CertStoreLocation cert:\LocalMachine\Root\ `
    -FilePath C:\users\YOUR-USER\Downloads\ca-cert.pem
```
This will import the certificate into the root store on your computer. You can check the GUI by opening the "Manage Computer Certificates" snap-in in MMC. 

In the same powershell window, add the VPN to windows via Powershell:
```
Add-VpnConnection -Name "VPN test" `
    -ServerAddress "DDNSADDR.ddns.net" `
    -TunnelType "IKEv2" `
    -AuthenticationMethod "EAP" `
    -EncryptionLevel "Maximum" `
    -RememberCredential `
```
Next, set the encryption methods to use for this VPN, as the default windows uses are too weak for strongswan to accept.
```
Set-VpnConnectionIPsecConfiguration -Name "VPN test" `
    -AuthenticationTransformConstants GCMAES256 `
    -CipherTransformConstants GCMAES256 `
    -DHGroup ECP384 `
    -IntegrityCheckMethod SHA384 `
    -PfsGroup ECP384 `
    -EncryptionMethod GCMAES256
```
Once this is done, you should be able to hit the windows network icon and connect to the VPN. It will ask for credentials, enter the credentials saved in /etc/ipsec.secrets. 


If all is well, you should connect! If not, see the references 

From the server, you can use the following to view the connected sessions: 

> sudo ipsec statusall 


References: 
DDNS configuration: 
https://www.blackmoreops.com/2020/11/18/how-to-install-the-noip2-on-ubuntu-and-run-via-systemd-systemctl-noip-dynamic-update-client/ 

IPSEC configuration: 
https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-20-04

Issue I ran into when getting the certificate identification to work: 
https://github.com/strongswan/strongswan/discussions/1351#discussioncomment-5189329 

Strongswan.conf configuration file: 
https://docs.strongswan.org/docs/5.9/config/strongswanConf.html 