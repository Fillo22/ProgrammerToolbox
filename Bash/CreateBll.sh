#!/bin/bash

# Ottenere il nome della cartella corrente
current_folder=$(basename "$PWD")

# Aggiungere il suffisso .Bll al nome della cartella
project_name="$current_folder.Bll"

# Creare il progetto .NET Class Library
dotnet new classlib -n "$project_name"

# Creare le cartelle Options, Logic e Interfaces
mkdir "$project_name/Options" "$project_name/Logic" "$project_name/Interfaces"

# Spostarsi nella cartella del progetto
cd "$project_name"

# Visualizzare un messaggio di successo
echo "Progetto $project_name creato con successo!"

# Elencare i progetti disponibili nella cartella corrente
projects=($(find .. -maxdepth 1 -type d -name '*.csproj' | sed 's:^\.\./::' | sed 's/\.csproj$//'))
num_projects=${#projects[@]}

# Verificare se ci sono progetti disponibili
if [ $num_projects -gt 0 ]; then
    echo "Progetti disponibili:"
    for ((i=0; i<$num_projects; i++)); do
        echo "$(($i + 1)). ${projects[$i]}"
    done

    # Selezione interattiva del progetto da referenziare
    read -p "Seleziona il numero del progetto da referenziare: " selected_index

    # Verifica che l'input sia un numero valido
    if [[ ! $selected_index =~ ^[0-9]+$ ]] || ((selected_index < 1)) || ((selected_index > num_projects)); then
        echo "Input non valido. Uscita."
        exit 1
    fi

    selected_project="${projects[$(($selected_index - 1))]}"
    
    # Aggiungere il riferimento al progetto selezionato nel file .csproj
    sed -i "s:</Project>:\t<ProjectReference Include=\"../$selected_project/$selected_project.csproj\" />\n</Project>:" "$project_name.csproj"

    echo "Progetto $project_name referenziato con successo al progetto $selected_project."
else
    echo "Nessun progetto disponibile per la referenza."
fi

