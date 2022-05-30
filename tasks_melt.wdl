version 1.0

task call_MELT_step1{
    meta {
        description: "Call t Mobile Elemen using MELT step1"
    }
    input {
        String docker = "alexeyebi/bowtie2_samtools"

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

        File MELT

        Array[File] me_refs

        Int NUM_THREAD = 5 
        String MEMORY = "10 GB"
        
    }

    String bam = basename(inputBAM)
    String bai = basename(bamIndex)

    command {
        # generate mei_list
        ls ${sep = ' ' me_refs} > mei_list.txt

        # symbol link bam and bai file to execution directory, failed in glob procedure
        # try to introduce by cp to ., glob would condain the bam to output which occupy too much storage
        # cp to subdirectory instead
        # ln -s to subdirectory also works, choose this for cp io reduction
        # mkdir input && cp ${inputBAM} input && cp ${bamIndex} input
        mkdir input && ln -s ${inputBAM} input && ln -s ${bamIndex} input
        

        java -jar ${MELT} Preprocess \
        -h ${RefFasta} \
        -bamfile input/${bam} 

        java -jar ${MELT} IndivAnalysis \
        -c 10 \
        -bamfile input/${bam} \
        -t mei_list.txt \
        -w . \
        -h ${RefFasta}


    }
    runtime {
        docker: docker 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"
    }
    output {
        # get all the output as array
        Array[File] output_step1 = glob("*")
    }
}

task call_MELT_step2{
    meta {
        description: "Call t Mobile Elemen using MELT step2"
    }
    input {
        String docker = "alexeyebi/bowtie2_samtools"

        Array[File] step1_output

        File RefFasta
        File RefIndex
        File RefDict
        File Refamb
        File Refann
        File Refbwt
        File Refpac
        File Refsa

        File MELT

        File bed
        Array[File] me_refs

        Int NUM_THREAD = 5 
        String MEMORY = "10 GB"
        
    }
    # test for output the input array before locolization. It remains the path before localization
    #File step1_outfile_list=write_lines(step1_output)
    command {
        # generate mei_list
        ls ${sep = ' ' me_refs} > mei_list.txt
        
        # copy step1 scatter output to one directory
        # python interpreter in the cromwell does not support class annotation, remove these annotations.
        mkdir step1
        python <<CODE
        import shutil
        import os

        def get_files_from_path(path):
            files = []
            
            for subunit in os.listdir(path):
                subpath = os.path.join(path,subunit)
                if os.path.isfile(subpath):
                    files.append(subpath)
                elif os.path.isdir(subpath):
                    files.extend(get_files_from_path(subpath))
            
            return files
        # get file lists from the relative path
        file_lists = get_files_from_path('../inputs')

        for file in file_lists:
            shutil.copy(file,'step1')
        CODE
 
        java -jar ${MELT} GroupAnalysis \
        -discoverydir step1 \
        -w . \
        -h ${RefFasta} \
        -t mei_list.txt \
        -n ${bed}

    }
    runtime {
        docker: docker 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"
    }
    output {
        # get all the output as array
        Array[File] output_step2 = glob("*")
    }
}

task call_MELT_step3{
    meta {
        description: "Call t Mobile Elemen using MELT step3"
    }
    input {
        String docker = "alexeyebi/bowtie2_samtools"

        File inputBAM
        File bamIndex
        Array[File] step2_output

        File RefFasta
        File RefIndex
        File RefDict
        File Refamb
        File Refann
        File Refbwt
        File Refpac
        File Refsa

        File MELT

        Array[File] me_refs

        Int NUM_THREAD = 5 
        String MEMORY = "10 GB"
        
    }
    command {
        # generate mei_list
        ls ${sep = ' ' me_refs} > mei_list.txt

        # cp step2 files to a certain folder
        mkdir step2 && cp ${sep = ' ' step2_output} step2

        java -jar ${MELT}  Genotype \
        -h ${RefFasta} \
        -bamfile ${inputBAM} \
        -p step2 \
        -t mei_list.txt \
        -w . 
        
    }
    runtime {
        docker: docker 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"
    }
    output {
        # get all the output as array
        Array[File] output_step3 = glob("*")
    }
}

task call_MELT_step4{
    meta {
        description: "Call t Mobile Elemen using MELT step4"
    }
    input {
        String docker = "alexeyebi/bowtie2_samtools"

        Array[File] step2_output
        Array[File] step3_output

        File RefFasta
        File RefIndex
        File RefDict
        File Refamb
        File Refann
        File Refbwt
        File Refpac
        File Refsa

        File MELT

        Array[File] me_refs

        Int NUM_THREAD = 5 
        String MEMORY = "10 GB"
        
    }
    command {
        # generate mei_list
        ls ${sep = ' ' me_refs} > mei_list.txt
        
        # cp step2 files to a certain folder
        mkdir step2 && cp ${sep = ' ' step2_output} step2

        # copy step3 scatter output to one directory
        mkdir step3 && cp ${sep = ' ' step3_output} step3
 
        java -jar ${MELT} MakeVCF \
        -h ${RefFasta} \
        -genotypingdir step3 \
        -t mei_list.txt \
        -p step2 \
        -w . 
    }
    runtime {
        docker: docker 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"
    }
    output {
        # get all the output as array
        Array[File] output_step4 = glob("*")
    }
}
