# docker

This directory previously contained a Dockerfile for a custom Nexus 3 image with the community GCS blob store plugin.

The custom image was removed for two reasons:

1. The [nexus-blobstore-google-cloud](https://github.com/sonatype-nexus-community/nexus-blobstore-google-cloud) plugin is archived and no longer maintained.
2. GCS blob store support requires Nexus Repository Pro. The OSS edition rejects the plugin at startup due to a license check.

The deployment now uses the official `sonatype/nexus3` image. Storage uses a local filesystem PVC provisioned by `kustomize/base/pvc.yaml`.

