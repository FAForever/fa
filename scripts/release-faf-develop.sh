
git checkout faforever/deploy/fafdevelop 
git pull faforever deploy/fafdevelop 

git checkout faforever/develop
git pull faforever develop 
git pull faforever deploy/fafdevelop --rebase
git push faforever HEAD:develop 

git checkout faforever/master 
git pull faforever master 
git pull faforever develop --rebase
git push faforever HEAD:master

git checkout faforever/deploy/faf 
git pull faforever deploy/faf  
git pull faforever master --rebase
git push faforever HEAD:deploy/faf