# Ansible Playbook to Download RKE2 Installation Artifacts

This is a very simple [Ansible](https://www.ansible.com) playbook to download installation 
artifacts to a specified folder for installation in an Air-Gapped network.

The tasks here were based upon the [rke2 Ansible Role](https://galaxy.ansible.com/lablabs/rke2) by [Labyrinth Labs](https://lablabs.io/).  

I manage an off-net network and wanted to find an easy way to download the artifacts that can be used to setup [RKE2](https://docs.rke2.io/install/quickstart)
in my environment.  Their role included some great tasks that verified SHA256 hashes of the downloads to increase trust in the resulting
repository.

Other than that, nothing really special about this.
