version 1.0

task call_GangSTR{
    meta {
        description: "Call tandem repeats using GangSTR"
    }
    input {
        String docker = "registry.miracle.ac.cn/miracle_cloud/str-toolkit:v1"

        String sampleName
        File inputBAM
        File bamIndex

        File RefFasta
        File RefIndex
        File RefDict
        File Refamb
        File Refann
        File Refbwt
        File Refpac
        File Refsa

        File TRregions

        Int NUM_THREAD = 5 
        String MEMORY = "10 GB"
        
    }
    command {
        GangSTR --bam ${inputBAM} \
        --ref ${RefFasta} \
        --regions ${TRregions} \
        --out ${sampleName} \
        --include-ggl \
        --bam-samps ${sampleName} \
        --output-readinfo


        
        # to produce a explict output
        ls ${sampleName}.vcf
        ls ${sampleName}.readinfo.tab
        ls ${sampleName}.samplestats.tab
        ls ${sampleName}.insdata.tab
    }
    runtime {
        docker: docker 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"
    }
    output {
        File vcf="${sampleName}.vcf"
        File readinfo = "${sampleName}.readinfo.tab"
        File samplestats = "${sampleName}.samplestats.tab"
        File insdata = "${sampleName}.insdata.tab"
    }
}




task call_CNVnator{
    meta {
        description: "Call CNV using CNVnator"
    }
    input {
        String docker = "registry-vpc.miracle.ac.cn/miracle_cloud/cnvnator:v1.1"

        String sampleName
        File inputBAM

        File bamIndex
        Array[File] splitRefs

        Int NUM_THREAD = 5 
        String MEMORY = "10 GB"
        
    }
    command {
        # copy splitRefs to cwd
        cp ${sep = ' ' splitRefs} .

        # extracting reads from bam
        cnvnator -root ${sampleName}.root \
        -chrom chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 \
        -tree ${inputBAM}

        # Generating a read depth histogram
        cnvnator -root ${sampleName}.root \
        -his 100 

        # Calculating statistics
        cnvnator -root ${sampleName}.root \
        -stat 100

        # RD signal partitioning
        cnvnator -root ${sampleName}.root \
        -partition 100

        # CNV calling
        cnvnator -root ${sampleName}.root \
        -call 100 \
        > ${sampleName}.cnvnator

        # Exporting CNV calls as VCFs
        cnvnator2VCF.pl -prefix ${sampleName} \
        -reference GRCh38 \
        ${sampleName}.cnvnator \
        . \
        > ${sampleName}.cnvnator.vcf

    }
    runtime {
        docker: docker 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"
    }
    output {
        File vcf="${sampleName}.cnvnator.vcf"
        File cnvnator = "${sampleName}.cnvnator"
    }
}
