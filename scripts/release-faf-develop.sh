
git checkout faforever/deploy/fafdevelop 
git pull faforever deploy/fafdevelop 

read

git checkout faforever/develop
git pull faforever develop 
git pull faforever deploy/fafdevelop --rebase
git push faforever HEAD:develop 

read

git checkout faforever/deploy/fafbeta
git pull faforever deploy/fafbeta 
git pull faforever develop --rebase
git push faforever HEAD:deploy/fafbeta 

read

git checkout faforever/master 
git pull faforever master 
git pull faforever develop --rebase
git push faforever HEAD:master

read

git checkout faforever/deploy/faf 
git pull faforever deploy/faf  
git pull faforever master --rebase
git push faforever HEAD:deploy/faf

read