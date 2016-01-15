# Open edX multi-server, horizontally scalable deployment on Azure

This is an Azure template to create two Ubuntu VMs: 
- One MySQL server (v5.6)
- One MongoDB server (v2.6)
and one horizontally scalable application server behind a load balancer.

You can learn more about Open edX here:
- https://open.edx.org
- https://github.com/edx/edx-platform

This template will complete quickly, but the full Open edX install usually takes > 1 hour. To follow along with the progress, ssh into the VM application server and `tail -f /var/log/azure/openedx-scalable-install.log`

The first application server (VM-APP0) provisions all of the other machines. The loadbalancer allows ssh to pass through to this virtual machine over port 2222. So use:
```
ssh -p2222 YOUR_USER_NAME@YOUR_INSTNACES_DNS_NAME.cloudapp.azure.com
```
to access. Once inside VM-APP0, you can ssh into any other VM using its private IP address.
- Application servers (1-9): 10.0.0.10 to 10.0.0.19
- MySQL: 10.0.0.20
- MongoDB: 10.0.0.30

# Getting started with Open edX fullstack
After the install has successfully completed, Supervisor will automatically start LMS (the student facing site) on port 80 and Studio (the course authoing site) on port 18010. Both ports have already been made accessible, so you can simply visit them by opening a browser and navigating to:
 - LMS: http://YOUR_INSTANCES_DNS_NAME.cloudapp.azure.com 
 - Studio: http://YOUR_INSTANCES_DNS_NAME.cloudapp.azure.com:18010

# Customizing Open edX multiserver
This branch is for a pilot instance deployed with [Azure Powershell] (https://msdn.microsoft.com/en-us/library/azure/dn654593.aspx). A custom server-vars.yml configuration is secure copied to the app server post-deployment and used to customize the instance.

Post-installation runtime configuration can be done by editing the file in `/edx/app/edx_ansible/server-vars.yml`.

After you have added your customizations, save your file, then run:
```
/edx/bin/update edx-platform YOUR_EDX_PLATFORMS_BRANCH_NAME
```

# Customizing Open edX's design
This branch uses a custom theme forked from [Stanford] (https://github.com/Stanford-Online/edx-theme). You can read more about [configuring an Open edX theme](https://github.com/edx/edx-platform/wiki/Stanford-Theming).

For more info, check the [Open edX Github Wiki on managing fullstack](https://github.com/edx/configuration/wiki/edX-Managing-the-Full-Stack)
