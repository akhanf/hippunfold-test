configfile: 'config.yml'

datasets=config['datasets'].keys()
versions=config['versions'].keys()

def get_all_hippunfold():
    files = []
    for dataset in config['datasets'].keys():
    
        files.extend(expand('hippunfold/{version}/{dataset}/sub-{subject}',
            version=config['versions'].keys(),
            dataset=dataset,
            subject=config['datasets'][dataset]['expand']['wildcards']['subject']))
    return files
    

rule all:
    input: get_all_hippunfold()


def files_to_get(wildcards):
    
    ds_expand = config['datasets'][wildcards.dataset]['expand']

    return expand(ds_expand['file'],**ds_expand['wildcards'])
    

rule get_dataset:
    params:
        url=config['datalad_url'],
        files_to_get=files_to_get   
    output:
        directory('datasets/{dataset}')
    shell:
        'datalad clone {params.url} {output} && '
        ' cd {output} && '
        ' datalad get {params.files_to_get}' 

rule run_hippunfold_subject:
    input:
        bids='datasets/{dataset}'
    params:
        container=lambda wildcards: config['versions'][wildcards.version]['container'],
        modality=lambda wildcards: config['datasets'][wildcards.dataset]['modality']
    output:
        directory('hippunfold/{version}/{dataset}/sub-{subject}')
    threads: 16
    shell:
        'singularity run -e {params.container} {input.bids} {output} participant --participant-label {wildcards.subject} '
        ' --modality {params.modality} -c {threads}'




