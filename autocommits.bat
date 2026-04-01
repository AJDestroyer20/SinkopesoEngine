@echo off
title autocommiter - commits automaticos beibe
echo NO USAR SI NO ERES OWNER DEL REPO, ESTO AUTOMATICAMENTE CREARA UN COMMIT CON LO QUE HAYAS CAMBIADO
echo Adding changes...
echo.
set /p commitMessage=Nombre del commit:

echo.
echo Commiteando...
git commit -m "%commitMessage%"

echo.
echo Pull porsiacaso...
git pull origin main --allow-unrelated-histories

echo.
echo Puchandole al gitHub...
git push origin main

echo.
echo ya quedo!
pause
