Versapay Infrastructure Cookbooks

Overview
========

This is a collection of cookbooks that uses chef to build reliable,
redudant, secure, pci compliant, infrastrucure for hosting web
applications.

CERTIFICATES
=============
Rake tasks exists for generating ssl certificates and a root ca.
Creating a new root ca
----------------------
rake ca_cert

Creating an ssl certificate signed by this ca_cert
---------------------------------
rake signed_ssl_cert FQDN=server_fqdn.example.com

* enter the fqdn for the ssl cert
* this needs to be done for many services.  Any app servers, proxies,
  ldap servers, ci-servers, and splunks servers

Splunk Certificates
------------------
Splunk requires mad ssl certs run these commands to get all setup

splunk root ca
------------------
rake splunk_root_ca FQDN=whatever.example.com

splunk ssl cert for each indexer
--------------------------------
rake splunk_ssl_cert FQDN=fqdn_of_indexer

Be sure to setup node.splunk.forwarder.ssl_password to the passphrase of
the indexers ssl keyfile for each splunk indexer
