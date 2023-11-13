@echo off
setlocal enabledelayedexpansion

REM Ottenere il nome della cartella corrente
for %%I in ("%CD%") do set "current_folder=%%~nxI"

REM Aggiungere il suffisso .Bll al nome della cartella
set "project_name=!current_folder!.Bll"

REM Creare il progetto .NET Class Library
dotnet new classlib -n !project_name!

REM Creare le cartelle Options, Logic e Interfaces
mkdir !project_name!\Options !project_name!\Logic !project_name!\Interfaces

REM Spostarsi nella cartella del progetto
cd !project_name!

REM Visualizzare un messaggio di successo
echo Progetto !project_name! creato con successo!

REM Elencare i progetti disponibili nella cartella corrente
set "num_projects=0"
for /f "delims=" %%a in ('dir /b /ad ..\*.csproj') do (
    set /a num_projects+=1
    set "projects[!num_projects!]=%%~na"
    echo !num_projects!. %%~na
)

REM Verificare se ci sono progetti disponibili
if !num_projects! gtr 0 (
    set /p "selected_index=Seleziona il numero del progetto da referenziare: "

    REM Verifica che l'input sia un numero valido
    if not "!selected_index!" lss "1" if not "!selected_index!" gtr "!num_projects!" (
        echo Input non valido. Uscita.
        exit /b 1
    )

    set "selected_project=!projects[%selected_index%]!"

    REM Aggiungere il riferimento al progetto selezionato nel file .csproj
    echo ^<ProjectReference Include="..\!selected_project!\!selected_project!.csproj" /^^^>^>> !project_name!.csproj

    echo Progetto !project_name! referenziato con successo al progetto !selected_project!.
) else (
    echo Nessun progetto disponibile per la referenza.
)

:end

