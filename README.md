# Deploy Open edX native on multiple Ubuntu VMs

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fchenriksson%2Fopenedx-azure-scalable%2Fcontribute%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fchenriksson%2Fopenedx-azure-scalable%2Fcontribute%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template deploys the Open edX native on Ubuntu VMs. Deployment supports up to 9 application VMs and separate, backend Mongo and MySQL VMs. A default server-vars.yml is saved to */edx/app/edx_ansible*.

Connect to the application VMs with SSH: `ssh {adminUsername}@{dnsLabelPrefix}.{region}.cloudapp.azure.com -p {frontendPort}`, where the frontendPort is 2222 for the first application VM, and 2223-222X for others. Installation log can be found under */var/log/azure*.

Private IPs inside the virtual network are:
- Application VMs: 10.0.0.10-10.0.0.19
- MySQL VM: 10.0.0.20
- Mongo VM: 10.0.0.30

You can learn more about Open edX and fullstack here:
- [Open edX](https://open.edx.org)
- [Installation Options](https://openedx.atlassian.net/wiki/display/OpenOPS/Open+edX+Installation+Options)
- [Running FullStack](https://openedx.atlassian.net/wiki/display/OpenOPS/Running+Fullstack)
- [Source Code](https://github.com/edx/edx-platform)

*Note that this template uses a different license than the [Open edX](https://github.com/edx/edx-platform/blob/master/LICENSE) platform.*