module github.com/lordofsystem/cert-manager-webhook-powerdns

go 1.13

require (
	github.com/jetstack/cert-manager v1.7.1
	github.com/joeig/go-powerdns/v2 v2.4.1
	github.com/miekg/dns v1.1.43 // indirect
	k8s.io/apiextensions-apiserver v0.23.1
	k8s.io/apimachinery v0.23.1
	k8s.io/client-go v0.23.1
	k8s.io/klog v1.0.0
)
