# ACME webhook for PowerDNS API

[![Release Charts](https://github.com/lordofsystem/cert-manager-webhook-powerdns/actions/workflows/release.yml/badge.svg?branch=master)](https://github.com/lordofsystem/cert-manager-webhook-powerdns/actions/workflows/release.yml)

This solver can be used when you want to use cert-manager with PowerDNS HTTP API. API documentation is [here](https://doc.powerdns.com/authoritative/http-api/#)

## Requirements
-   [go](https://golang.org/) >= 1.13.0
-   [helm](https://helm.sh/) >= v3.0.0
-   [kubernetes](https://kubernetes.io/) >= v1.14.0
-   [cert-manager](https://cert-manager.io/) >= 0.12.0

## Installation

### cert-manager

Follow the [instructions](https://cert-manager.io/docs/installation/) using the cert-manager documentation to install it within your cluster.

### Webhook

#### Using public helm chart
```bash
helm repo add cert-manager-webhook-powerdns https://lordofsystem.github.io/cert-manager-webhook-powerdns
# Replace the groupName value with your desired domain
helm install --namespace cert-manager cert-manager-webhook-powerdns cert-manager-webhook-powerdns/cert-manager-webhook-powerdns --set groupName=acme.yourdomain.tld
```

#### From local checkout

```bash
helm install --namespace cert-manager cert-manager-webhook-powerdns deploy/cert-manager-webhook-powerdns
```
**Note**: The kubernetes resources used to install the Webhook should be deployed within the same namespace as the cert-manager.

To uninstall the webhook run
```bash
helm uninstall --namespace cert-manager cert-manager-webhook-powerdns
```

## Issuer

Create a `ClusterIssuer` or `Issuer` resource as following:
```yaml
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory

    # Email address used for ACME registration
    email: mail@example.com # REPLACE THIS WITH YOUR EMAIL!!!

    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging

    solvers:
      - dns01:
          webhook:
            # This group needs to be configured when installing the helm package, otherwise the webhook won't have permission to create an ACME challenge for this API group.
            groupName: acme.yourdomain.tld
            solverName: pdns
            config:
              zone: example.com # Optional, see below
              domain: _acme-challenge.example.com # Optional, see below
              secretName: pdns-secret
              apiUrl: https://powerndns.com
              serverName: localhost # Optional, default is 'localhost'
```

### Credentials
In order to access the HTTP API, the webhook needs an API token.

If you choose another name for the secret than `pdns-secret`, ensure you modify the value of `secretName` in the `[Cluster]Issuer`.

The secret for the example above will look like this:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pdns-secret
type: Opaque
data:
  api-key: your-key-base64-encoded
```

### Optional zone and domain

The 'zone' and 'domain' config settings are optional. If they are not provided in the config, 
they are automatically extracted from certificate request (if you need a certificate for
"subdomain.example.com", the zone and and domain will be set to "example.com" and 
"_acme-challenge.subdomain.example.com". This is exactly what you need to create TXT records
in a regular authoritative name server.

If you however use a dedicated DNS server that you exclusively use for ACME challenges so that
you do not have to open up the API of your regular DNS server, you can use an alternative setup
instead. To run a dedicated DNS server for only the acme challenges, make sure you create
this configuration in your main DNS server:

```
acme-dns-server.example.com     A           1.2.3.4
acme-challenges.example.com     NS          acme-dns-server.example.com
_acme-challenge.example.com     CNAME       example-com.acme-challenges.example.com
_acme-challenge.example.org     CNAME       example-org.acme-challenges.example.com
_acme-challenge.example.net     CNAME       example-net.acme-challenges.example.com
```

The above configuration specifies that you have a dedicated DNS server accessible via
IP 1.2.3.4, and that this server is authoratative for all "*.acme-challenges.example.com"
subdomains. You also create one or more static CNAME records for your acme challenges 
that point to such subdomains.

In the "config" section of your `ClusterIssuer` or `Issuer` you can then set the 
domain to `example-com.acme-challenges.example.com`, the zone to 
`acme-challenges.example.com` and the apiUrl to `http://acme-dns-server.example.com`.
The challenges will then be hosted in an exclusive DNS server and your main DNS
server does not have to open its API.


### Create a certificate

Finally you can create certificates, for example:

```yaml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: example-cert
  namespace: cert-manager
spec:
  commonName: example.com
  dnsNames:
    - example.com
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  secretName: example-cert
```

## Development

### Running the test suite

All DNS providers **must** run the DNS01 provider conformance testing suite,
else they will have undetermined behaviour when used with cert-manager.

**It is essential that you configure and run the test suite when creating a
DNS01 webhook.**

You must encode your api token into base64 and put the hash into `testdata/pdns/pdns-secret.yml` file.

You can then run the test suite with:

```bash
# first install necessary binaries (only required once)
./scripts/fetch-test-binaries.sh
# then run the tests
TEST_ZONE_NAME=example.com. make verify
```
