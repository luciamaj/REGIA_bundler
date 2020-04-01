#!/usr/bin/env ruby

require 'json'
require 'fileutils'

# TODO: Il bundler funziona solo se lanciato dalla directory in cui e' l'eseguibile

$dir = File.dirname(File.realpath(__FILE__))

connettori = Dir["#{$dir}/connettori/*"].map { |p| File.basename(p) }

def versioni(connettore)
    Dir.chdir("pacchetti/#{connettore}") do
        versioni = `git log master --pretty=format:"%h" | cut -d " " -f 1`.split("\n")
        return versioni
    end
end

def log(connettore)
    Dir.chdir("pacchetti/#{connettore}") do
        log = `git log master --pretty=format:"%h"`
        return log
    end
end

def publish(connettore)
    jsonData = `#{$dir}/connettori/#{connettore}`;
    data = JSON.parse(jsonData);
    
    name = connettore
    # name = data["name"];

    layout = data["layout"];
    dataString = <<-Q
export default
#{jsonData}
    Q

    # TODO: Spostare in def init(connettore)
    Dir.mkdir("pacchetti") unless File.exists?("pacchetti")
    Dir.mkdir("pacchetti/#{name}") unless File.exists?("pacchetti/#{name}")
    Dir.mkdir("pacchetti/#{name}/layout") unless File.exists?("pacchetti/#{name}/layout")
    Dir.mkdir("pacchetti/#{name}/assets") unless File.exists?("pacchetti/#{name}/assets")

    Dir.chdir("pacchetti/#{name}") do
        status = `git status 2>&1`
        if status.include? "ot a git repository"
            puts "Creando repo di git"
            `git init`
            puts ""
        end

        backToMaster = `git checkout master 2>&1`
        if backToMaster.include? "Switched"
            puts "Tornato all'ultimo commit, rilanciare per pubblicare le ultime modifiche"
            exit
        end
    end

    FileUtils.cp_r("layouts/#{layout}/.", "pacchetti/#{name}/layout")
    File.write("pacchetti/#{name}/data.js", dataString);
    filesRegex = /\"([^\"]+\.[^\"]+)\"/
    files = jsonData.scan(filesRegex).map { |m| m[0] }
    puts "Asset da caricare"
    files.each { |f|
        path = "assets/#{f}"
        # puts path;
        if File.file?(path)
            puts "\u2713 #{path}"
            FileUtils.ln_sf(File.realpath(path), "pacchetti/#{name}/assets")
        else
            puts "\u2717 #{path}"
        end
    }
    puts ""

    filesInFolder = Dir["#{$dir}/pacchetti/#{name}/assets/*"].map { |p| File.basename(p) }
    filesInFolder.each { |f| 
        path = "#{$dir}/pacchetti/#{name}/assets/#{f}"
        if !files.include?(f) 
            # puts "Removing #{path}"
            FileUtils.rm(path)
        end
    }
    
    Dir.chdir("pacchetti/#{name}") do
        status = `git status 2>&1`
        if status.include? "working tree clean"
            puts "Niente di nuovo da pubblicare"
            exit
        end

        `git add -A .`
        `git commit -m "#{Time.now}"`
    end
    
    puts "Versioni:"
    puts log(connettore)

end

if ARGV.length == 0
    puts <<-Q
Comandi
#{$0} pubblica <connettore>
#{$0} versioni <connettore>
#{$0} versione_corrente <connettore>
#{$0} resetta <connettore> <versione>
#{$0} connettori
    Q
elsif ARGV[0] == 'pubblica'
    connettore = ARGV[1]
    if !connettori.include?(connettore)
        puts "#{$0} pubblica <connettore>"
        exit
    end

    publish(connettore)
elsif ARGV[0] == 'versione_corrente'
    connettore = ARGV[1]
    if !connettori.include?(connettore)
        puts "Non trovo il connettore '#{connettore}'"
        puts "#{$0} versione_corrente <connettore>"
        exit
    end

    Dir.chdir("pacchetti/#{connettore}") do
        versione = `git log -1 --pretty=format:"%h"`
        puts versione
    end


elsif ARGV[0] == 'resetta'
    connettore = ARGV[1]
    if !connettori.include?(connettore)
        puts "Non trovo il connettore '#{connettore}'"
        puts "#{$0} resetta <connettore> <versione>"
        exit
    end

    versione = ARGV[2]
    if !versione
        puts "#{$0} resetta <connettore> <versione>"
        puts "Non trovo la versione '#{versione}'"
        puts ""
        puts "Versioni disponibili:"
        puts versioni(connettore)
        exit
    end

    versioni = versioni(connettore)
    selezionata = versioni.detect { |v| v.include?(versione) }
    if !selezionata
        puts "#{$0} resetta <connettore> <versione>"
        puts "Non trovo la versione '#{versione}'"
        puts ""
        puts "Versioni disponibili:"
        puts versioni(connettore)
        exit
    end
        
    puts "Resetto a #{selezionata}"
    Dir.chdir("pacchetti/#{connettore}") do
        `git checkout #{selezionata} 2>&1`
    end

elsif ARGV[0] == 'versioni'
    connettore = ARGV[1]
    if !connettori.include?(connettore)
        puts "#{$0} versioni <connettore>"
        exit
    end

    puts log(connettore)

elsif ARGV[0] == 'connettori'
    connettori.each { |c| puts c }
end

exit
