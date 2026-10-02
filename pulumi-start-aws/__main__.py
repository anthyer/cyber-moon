"""Infraestrutura do Cyber Moon na AWS: bucket privado para os builds exportados do jogo."""

import pulumi
from pulumi_aws import route53, s3

# Tags aplicadas a todos os recursos, para identificar o projeto e o stack no console da AWS.
common_tags = {
    'Project': 'cyber-moon',
    'Stack': pulumi.get_stack(),
    'ManagedBy': 'pulumi',
}

# Bucket que guarda os builds exportados pelo Godot.
# O Pulumi acrescenta um sufixo aleatório ao nome físico, então não há conflito de nome global.
builds_bucket = s3.Bucket(
    'cyber-moon-builds',
    tags=common_tags,
)

# Bloqueia qualquer forma de acesso público ao bucket.
builds_bucket_public_access_block = s3.BucketPublicAccessBlock(
    'cyber-moon-builds-public-access-block',
    bucket=builds_bucket.id,
    block_public_acls=True,
    block_public_policy=True,
    ignore_public_acls=True,
    restrict_public_buckets=True,
)

# Mantém as versões antigas dos arquivos, para recuperar um build sobrescrito por engano.
builds_bucket_versioning = s3.BucketVersioning(
    'cyber-moon-builds-versioning',
    bucket=builds_bucket.id,
    versioning_configuration={
        'status': 'Enabled',
    },
)

# Zona DNS do domínio do projeto. Só existe em produção, os outros stacks não têm domínio.
if pulumi.get_stack() == 'prod':
    route53.Zone(
        'cyber-moon',
        name='cyber-moon.negoci.online',
        tags=common_tags,
    )

# Exporta o nome físico do bucket, usado na hora de enviar os builds.
pulumi.export('builds_bucket_name', builds_bucket.id)
