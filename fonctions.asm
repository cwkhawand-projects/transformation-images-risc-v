#######################################################
############### TRIM #############################
# Arguments:
# - a0: addresse de la chaine de caracteres
fnTRIM:
	# ouverture
	addi sp, sp, -8
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 8
	
	li   t0, '\n'   # on s'arrete aussi aux nouvelles lignes
	lb   t1, 0(a0)
TANTQUE_TRIM:
	beqz t1, FIN_TRIM
	beq  t1, t0, FIN_TRIM

	addi a0, a0, 1
	lb   t1, 0(a0)
	
	j    TANTQUE_TRIM
FIN_TRIM:
	li   t0, '\0'
	sb   t0, 0(a0)  # on remplace '\n' par '\0'

	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 8
	ret
#######################################################
#######################################################

#######################################################
############### LITENTIER #############################
# Arguments:
# - a0: addresse du fichier avec le buffer positionne sur le debut de l'entier a lire
# Retour:
# - a0: addresse du message d'erreur si la lecture a echouee, 0 sinon
# - a1: l'entier lu
fnLITENTIER:
	# ouverture
	addi sp, sp, -8
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 8

	mv   t4, a0
	li   t0, 0                # entier lu
	li   t5, 10

TANTQUE_LITENTIER:
	# lecture d'un caractere
	li   a7, 63
	mv   a0, t4
	la   a1, car
	li   a2, 1
	ecall
	lb   t1, car

	li   t2, ' '
	beq  t1, t2, FIN_LITENTIER # on arrete de lire s'il y a un espace
	li   t2, '\n'
	beq  t1, t2, FIN_LITENTIER # ou un retour a la ligne
	beqz t1, FIN_LITENTIER     # ou la fin du fichier

	li   t3, '0'
	sub  t3, t1, t3            # t3 <= entierLu - '0' = (int) entierLu
	mul  t0, t0, t5            # t0 *= 10
	add  t0, t0, t3            # t0 += t3

	j TANTQUE_LITENTIER
FIN_LITENTIER:
	li   a0, 0
	mv   a1, t0

	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 8
	ret
#######################################################
#######################################################

#######################################################
############### ENTIERTOASCII #############################
# Arguments:
# - a0: L'entier a convertir en ascii
# Retour:
# - a0: addresse du message d'erreur si la conversion a echouee, 0 sinon
# - a1: l'addresse du premier caractere de l'espace alloue
# - a2: taille de la chaine de caracteres
fnENTIERTOASCII:
	# ouverture
	addi sp, sp, -8
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 8
	
	mv   t0, a0       # t0 <= entier
	li   a2, 0        # nombre de caracteres
	li   t2, 10
TANTQUE_COMPTE_ENTIERTOASCII:
	beqz t0, FIN_COMPTE_LITENTIER

	div  t0, t0, t2   # t0 <= quotient(entier/10)

	addi a2, a2, 1

	j TANTQUE_COMPTE_ENTIERTOASCII
FIN_COMPTE_LITENTIER:
	mv   t0, a0       # t0 <= entier

	addi t1, a2, 1    # t1 <= taille a allouer (inclus \0)
	# malloc(t1)
	li   a7, 9
	mv   a0, t1
	ecall

	mv   a1, a0       # a1 <= addresse allouee
	add  t1, a1, a2   # t1 <= addresse allouee + taille chaine

	# ajout du caractere de fin de chaine
	li   t4, '\0'
	sb   t4, 0(t1)
	addi t1, t1, -1
TANTQUE_CONVERTIT_ENTIERTOASCII:
	beqz t0, FIN_CONVERTIT_ENTIERTOASCII

	rem  t3, t0, t2   # t3 <= reste(entier/10)
	addi t3, t3, 48   # t3 <= t3 + '0' (0 en tant que ASCII)
	sb   t3, 0(t1)    # stockage du caractere dans le tableau alloue

	div  t0, t0, t2   # t3 <= quotient(entier/10)
	addi t1, t1, -1

	j TANTQUE_CONVERTIT_ENTIERTOASCII
FIN_CONVERTIT_ENTIERTOASCII:
	li   a0, 0

	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 8
	ret
#######################################################
#######################################################

#######################################################
############## LITFICHIER #############################
# Arguments:
# - a0: chemin du fichier a lire
# Retour:
# - a0: addresse du message d'erreur si la lecture a echouee, 0 sinon
# - a1: addresse du tableau rempli
# - a2: tailleX de l'image
# - a3: tailleY de l'image
# - a4: surface de l'image (tailleX*tailleY)
fnLITFICHIER:
	# ouverture
	addi sp, sp, -52
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 52

	li   t0, 2       # nombre de lignes a sauter (on suppose d'abord que c'est 2)

	# Ouverture du fichier
	li   a7, 1024    # ecall pour ouvrir un fichier
	li   a1, 0       # (0: read, 1: write)
	ecall

	# si on a pas pu ouvrir le fichier, return a0=-1, sinon a0=0
	bltz a0, ERR_LITFICHIER
	
	mv   t1, a0       # sauvegarde du descripteur du fichier dans t1
	li   t2, '\n'     # charactere de nouvelle ligne dans t2
	
	li   t3, 1        # nombre de characteres lus a chaque tour de boucle dans t3
	li   t4, 0        # numero de la ligne sur laquelle on est dans t4
	li   t5, 1        # on suppose qu'on a lu un charactere
	li   a6, 0        # compteur
	li   a3, 1        # ligne 2

TANTQUE_LITFICHIER:
	# Lecture de tout le fichier
	beqz t5, ERR_LITFICHIER # si fin du fichier prematuree, sortie avec erreur

	# lecture d'un caractere
	li   a7, 63
	mv   a0, t1
	la   a1, car
	mv   a2, t3
	ecall

	mv   t5, a0               # stockage du nombre de caracteres lu dans t5

	# stockage du caractere lu dans t6
	lb   t6, car

	blt  t4, t0, VERIFLF      # sauter les lignes qui ne contiennent pas l'image

	beq  t6, t2, VERIFLF      # pas de sauvegarde des caracteres LF

	sb   t6, 0(a5)            # stockage du caractere lu dans le tableau
	addi a5, a5, 1            # incrementation du l'addresse du tableau
	addi a6, a6, 1            # incrementation du compteur
	beq  a6, a4, SUITEFN_LITFICHIER      # sortie de la boucle quand on a lu long*larg
VERIFLF:
	bne  t6, t2, SUITETANTQUE_LITFICHIER
	addi t4, t4, 1
	bne  t4, a3, SUITETANTQUE_LITFICHIER # si ligne 2 continue

	# Prologue
	sw   t0, 8(sp)
	sw   t1, 12(sp)
	sw   t2, 16(sp)
	sw   t3, 20(sp)
	sw   t4, 24(sp)
	sw   t5, 28(sp)
	sw   t6, 32(sp)
	sw   a3, 36(sp)
	sw   a4, 40(sp)
	sw   a5, 44(sp)
	sw   a6, 48(sp)

	lw   a0, 12(sp)
	jal  fnLITENTIER
	sw   a1, tailleX, a0

	mv   a4, a1     # a4 <= tailleX
	sw   a4, 40(sp)

	lw   a0, 12(sp)
	jal  fnLITENTIER
	sw   a1, tailleY, a0

	lw   a4, 40(sp)
	mul  a4, a4, a1 # a4 <= tailleX*tailleY
	sw   a4, 40(sp)

	lw   a0, 12(sp)
	jal  fnLITENTIER
	sw   a1, nbCoul, a0

	lw   t0, 8(sp)
	add  t0, t0, a1 # mise a jour du nombre de lignes a sauter
	sw   t0, 8(sp)

	lw   a0, 12(sp)
	jal  fnLITENTIER
	sw   a1, carParCoul, a0   

	# allocation d'un tableau de long*larg et stockage de l'addresse dans a5
	li   a7, 9
	lw   a0, 40(sp) # 40(s0) = a4
	ecall

	mv   a5, a0
	sw   a5, 44(sp)

	# Epilogue
	lw   t0, 8(sp)
	lw   t1, 12(sp)
	lw   t2, 16(sp)
	lw   t3, 20(sp)
	lw   t4, 24(sp)
	lw   t5, 28(sp)
	lw   t6, 32(sp)
	lw   a3, 36(sp)
	lw   a4, 40(sp)
	lw   a5, 44(sp)
	lw   a6, 48(sp)

	addi t4, t4, 1 # on a lu toute la ligne jusqu'au \n, incrementer
SUITETANTQUE_LITFICHIER:
	j    TANTQUE_LITFICHIER

SUITEFN_LITFICHIER:
	blt  a6, a4, ERR_LITFICHIER

	# Fermeture du fichier
	li   a7, 57
	mv   a0, t1
	ecall

	# Reset de l'addresse du tableau
	sub  a5, a5, a4

	li   a0, 0
	mv   a1, a5

	lw   a2, tailleX
	lw   a3, tailleY

	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 52
	ret
ERR_LITFICHIER:
	# Fermeture du fichier
	li   a7, 57
	mv   a0, t1
	ecall

	la   a0, messErrLect

	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 52
	ret
#######################################################
#######################################################

#######################################################
############## ECRITFICHIER ###########################
# Arguments:
# - a0: addresse du fichier du fichier original
# - a1: addresse du fichier dans lequel ecrire
# - a2: nombre de couleurs
# - a3: nombre de caracteres par couleur
# - a4: addresse de la matrice a ecrire
# - a5: tailleX de la matrice a ecrire
# - a6: tailleY de la matrice a ecrire
# Retour:
# - a0: addresse du message d'erreur si l'ecriture a echouee, 0 sinon
fnECRITFICHIER:
	# ouverture
	addi sp, sp, -56
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	sw   a2, 52(sp)
	addi fp, sp, 56

	mv   t2, a1       # copie d'addresse du fichier dans lequel ecrire
	addi t0, a2, 2    # calcul du nombre de lignes a copier

	# Ouverture du fichier original
	li   a7, 1024     # ecall pour ouvrir un fichier
	li   a1, 0        # (0: read, 1: write)
	ecall

	# si on a pas pu ouvrir le fichier, return a0=-1, sinon a0=0
	bltz a0, ERR_ECRITFICHIER

	mv   t1, a0       # sauvegarde du descripteur du fichier dans t1

	# Ouverture du nouveau fichier
	li   a7, 1024     # ecall pour ouvrir un fichier
	mv   a0, t2
	li   a1, 1        # (0: read, 1: write)
	ecall

	# si on a pas pu ouvrir le fichier, return a0=-1, sinon a0=0
	bltz a0, ERR_ECRITFICHIER

	mv   t2, a0       # sauvegarde du descripteur du fichier dans t2

	li   t3, '\n'     # charactere de nouvelle ligne dans t3
	li   t4, 0        # nombre de lignes lues
	li   t5, 1
TANTQUE_ECRITFICHIER:
	bge  t4, t0, SUITE_ECRITFICHIER_1
	beq  t4, t5, ECRITFICHIER_DIM     # quand on atteint la ligne 2 (t4 = t5 = 1)
	# lecture d'un caractere
	li   a7, 63
	mv   a0, t1
	la   a1, car
	li   a2, 1
	ecall

	# ecriture du caractere dans le nouveau fichier
	li   a7, 64
	mv   a0, t2
	la   a1, car
	li   a2, 1
	ecall

	lb   t6, car      # stockage du caractere lu dans t6

	# si le caractere est \n, on ajoute 1 aux lignes lues
	bne  t6, t3, SUITETANTQUE_ECRITFICHIER
	addi t4, t4, 1
SUITETANTQUE_ECRITFICHIER:
	j    TANTQUE_ECRITFICHIER
ECRITFICHIER_DIM:
	# Prologue
	sw   t0, 8(sp)
	sw   t1, 12(sp)
	sw   t2, 16(sp)
	sw   t3, 20(sp)
	sw   t4, 24(sp)
	sw   t5, 28(sp)
	sw   t6, 32(sp)
	sw   a3, 36(sp)
	sw   a4, 40(sp)
	sw   a5, 44(sp)
	sw   a6, 48(sp)

	li   t0, ' '
	sb   t0, car, t1

	# ecriture de tailleX
	mv   a0, a5
	jal  fnENTIERTOASCII
	li   a7, 64
	lw   a0, 16(sp)
	ecall

	# ecriture d'un espace
	lw   a0, 16(sp)
	la   a1, car
	li   a2, 1
	ecall

	# ecriture de tailleY
	mv   a0, a6
	jal fnENTIERTOASCII
	li   a7, 64
	lw   a0, 16(sp)
	ecall

	# ecriture d'un espace
	lw   a0, 16(sp)
	la   a1, car
	li   a2, 1
	ecall

	# ecriture de nbCouleurs
	lw  a0, 52(sp)
	jal fnENTIERTOASCII
	li   a7, 64
	lw   a0, 16(sp)
	ecall

	# ecriture d'un espace
	lw   a0, 16(sp)
	la   a1, car
	li   a2, 1
	ecall

	# ecriture de nbCouleurs/car
	mv   a0, a3
	jal fnENTIERTOASCII
	li   a7, 64
	lw   a0, 16(sp)
	ecall

	# ecriture d'un retour a la ligne
	lw   a0, 16(sp)
	addi a1, sp, 20
	li   a2, 1
	ecall

	lw   t1, 12(sp)
	li   t3, '\n'
SAUT_LIGNE2:
	# while(car != '\n') // on saute la ligne 2
	li   a7, 63
	mv   a0, t1
	la   a1, car
	li   a2, 1
	ecall

	lb   a0, car
	beq  a0, t3, SUITE_ECRITFICHIER_DIM

	j SAUT_LIGNE2

SUITE_ECRITFICHIER_DIM:
	# Epilogue
	lw   t0, 8(sp)
	lw   t1, 12(sp)
	lw   t2, 16(sp)
	lw   t3, 20(sp)
	lw   t4, 24(sp)
	lw   t5, 28(sp)
	lw   t6, 32(sp)
	lw   a3, 36(sp)
	lw   a4, 40(sp)
	lw   a5, 44(sp)
	lw   a6, 48(sp)

	addi t4, t4, 1
	j   TANTQUE_ECRITFICHIER

SUITE_ECRITFICHIER_1:
	# Fermeture du fichier original
	li   a7, 57
	mv   a0, t1
	ecall

	li   t3, 0        # compteur
	li   t4, '\n'
	mul  t0, a5, a6   # tailleX*tailleY

	li   a7, 64       # ecriture dans un fichier
	li   a2, 1        # nombre de caracteres a ecrire
TANTQUE_ECRITMATRICE:
	bge  t3, t0, SUITE_ECRITFICHIER_2 # quand on a tout ecrit, on sort de la boucle

	# ecriture du caractere de la matrice dans le nouveau fichier
	mv   a0, t2       # descripteur du fichier ou ecrire
	lb   a1, 0(a4)
	sb   a1, car, t5
	la   a1, car
	ecall

	# incrementation de l'addresse du tableau et du compteur
	addi a4, a4, 1
	addi t3, t3, 1

	# ecriture des \n
	rem  t5, t3, a5
	bnez t5, SUITE_TANTQUE_ECRITMATRICE
	mv   a0, t2       # descripteur du fichier ou ecrire
	sb   t4, car, t5
	la   a1, car
	ecall
SUITE_TANTQUE_ECRITMATRICE:
	j    TANTQUE_ECRITMATRICE

SUITE_ECRITFICHIER_2:
	# Fermeture du nouveau fichier
	li   a7, 57
	mv   a0, t2
	ecall

	li   a0, 0

	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 52
	ret

ERR_ECRITFICHIER:
	# Fermeture des fichiers
	li   a7, 57
	mv   a0, t1
	ecall
	li   a7, 57
	mv   a0, t2
	ecall
 
	la   a0, messErrLect

	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 52
	ret
#######################################################
#######################################################

#######################################################
############### AFFICHEMATRICE ########################
# Arguments:
# - a0: tailleX de la matrice
# - a1: tailleY de la matrice
# - a2: addresse de la matrice a afficher
fnAFFICHEMATRICE:
	# ouverture
	addi sp, sp, -8
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 8

	mv   t0, a0       # tailleX de la matrice
	mv   t1, a1       # tailleY de la matrice

	li   t2, 0        # i
	li   t3, 0        # j
	li   t4, '\n'
	li   a7, 11       # affichage de caractere
TANTQUE_AFFICHEMATRICE:
	bge  t2, t1, SUITE_AFFICHEMATRICE # quand on a tout affiche, on sort de la boucle
	bge  t3, t0, FINLIGNE_AFFICHEMATRICE

	# affichage d'un caractere
	lb   a0, 0(a2)
	ecall

	# incrementation de l'addresse du tableau et du compteur
	addi a2, a2, 1
	addi t3, t3, 1

	j TANTQUE_AFFICHEMATRICE
FINLIGNE_AFFICHEMATRICE:
	mv   a0, t4
	ecall

	addi t2, t2, 1
	li   t3, 0
	j    TANTQUE_AFFICHEMATRICE

SUITE_AFFICHEMATRICE:
	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 8
	ret
#######################################################
#######################################################

#######################################################
############### COPIETAB ##############################
# Arguments:
# - a0: tailleX de la matrice
# - a1: tailleY de la matrice
# - a2: addresse de la matrice de destination
# - a3: addresse de la matrice a copier
fnCOPIETAB:
	mul  t1, a0, a1 # tailleX*tailleY

	li   t0, 0 # i
TANTQUE_COPIETAB:
	bge  t0, t1, SUITE_COPIETAB

	# matrice_dest[t0]
	add  t3, t0, a2

	# matrice_source[t0]
	add  t2, t0, a3

	# matrice_dest[t0] = matrice_source[t0]
	lb   t4, 0(t2)
	sb   t4, 0(t3)
	addi t0, t0, 1
	j    TANTQUE_COPIETAB

SUITE_COPIETAB:
	ret
#######################################################
#######################################################

#######################################################
############## INVLIGNES ##############################
# Arguments:
# - a0: tailleX de la matrice
# - a1: tailleY de la matrice
# - a2: addresse de la matrice a transformer
# - a3: addresse de la matrice temporaire de la meme taille
fnINVLIGNES:
	# ouverture
	addi sp, sp, -8
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 8

	li   t0, 0 # i
	li   t1, 0 # j
TANTQUE_INVLIGNES:
	bge  t0, a1, SUITE_INVLIGNES
	bge  t1, a0, SUITETANTQUE_INVLIGNES

	# matrice[t0][t1]
	mul  t2, t0, a0
	add  t2, t2, t1
	add  t2, t2, a2

	# matrice_temp[tailleY-1-t0][t1]
	addi t3, a1, -1
	sub  t3, t3, t0
	mul  t3, t3, a0
	add  t3, t3, t1
	add  t3, t3, a3

	# matrice_temp[taille-1-t0][t1] = matrice[t0][t1]
	lb   t4, 0(t2)
	sb   t4, 0(t3)
	addi t1, t1, 1
	j    TANTQUE_INVLIGNES
SUITETANTQUE_INVLIGNES:
	addi t0, t0, 1
	li   t1, 0
	j    TANTQUE_INVLIGNES
	
SUITE_INVLIGNES:
	# appel de fonction
	jal  fnCOPIETAB

	#fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 8

	ret
#######################################################
#######################################################

#######################################################
############## INVCOLONNES ############################
# Arguments:
# - a0: tailleX de la matrice
# - a1: tailleY de la matrice
# - a2: addresse de la matrice a transformer
# - a3: addresse de la matrice temporaire de la meme taille
# Retour:
# - a0: addresse de la matrice avec les colonnes inversees
fnINVCOLONNES:
	# ouverture
	addi sp, sp, -8
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 8

	li   t0, 0 # i
	li   t1, 0 # j
TANTQUE_INVCOLONNES:
	bge  t0, a1, SUITE_INVCOLONNES
	bge  t1, a0, SUITETANTQUE_INVCOLONNES

	# matrice[t0][t1]
	mul  t2, t0, a0
	add  t2, t2, t1
	add  t2, t2, a2

	# matrice_temp[t0][taille-1-t1]
	mul  t3, t0, a0
	add  t3, t3, a0
	addi t3, t3, -1
	sub  t3, t3, t1
	add  t3, t3, a3

	# matrice_temp[t0][taille-1-t1] = matrice[t0][t1]
	lb   t4, 0(t2)
	sb   t4, 0(t3)
	addi t1, t1, 1
	j    TANTQUE_INVCOLONNES
SUITETANTQUE_INVCOLONNES:
	addi t0, t0, 1
	li   t1, 0
	j    TANTQUE_INVCOLONNES

SUITE_INVCOLONNES:  
	# appel de fonction
	jal  fnCOPIETAB

	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 8

	ret
#######################################################
#######################################################

#######################################################
############## TRANSPOSE ##############################
# Arguments:
# - a0: tailleX de la matrice
# - a1: tailleY de la matrice
# - a2: addresse de la matrice a transposer
# - a3: addresse de la matrice temporaire de la meme taille
fnTRANSPOSE:
	# ouverture
	addi sp, sp, -8
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 8

	li   t0, 0 # i
	li   t1, 0 # j
TANTQUE_TRANSPOSE:
	bge  t0, a1, SUITE_TRANSPOSE
	bge  t1, a0, SUITETANTQUE_TRANSPOSE

	# matrice[t0][t1]
	mul  t2, t0, a0
	add  t2, t2, t1
	add  t2, t2, a2

	# matrice_temp[t1][t0]
	mul  t3, t1, a1
	add  t3, t3, t0
	add  t3, t3, a3

	# matrice_temp[t1][t0] = matrice[t0][t1]
	lb   t4, 0(t2)
	sb   t4, 0(t3)
	addi t1, t1, 1
	j    TANTQUE_TRANSPOSE
SUITETANTQUE_TRANSPOSE:
	addi t0, t0, 1
	li   t1, 0
	j    TANTQUE_TRANSPOSE
	
SUITE_TRANSPOSE:   
	# appel de fonction
	jal  fnCOPIETAB

	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 8

	ret
#######################################################
#######################################################

#######################################################
################ ROTATE ###############################
# Arguments:
# - a0: tailleX de la matrice
# - a1: tailleY de la matrice
# - a2: addresse de la matrice a tourner
# - a3: addresse de la matrice temporaire de la meme taille
# - a4: 0 si rotation de 180 degres, 1 si rotation de 90 degres
# - a5: 0 si rotation trigonometrique, 1 si rotation horaire
# Retour:
# - a0: addresse du message d'erreur si la rotation a echouee, 0 sinon
fnROTATE:
	# ouverture
	addi sp, sp, -8
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 8

	beqz a4, ECHANGEUR

	jal  fnTRANSPOSE   # appel de fonction

	# echange des dimensions
	mv   t0, a0
	mv   a0, a1
	mv   a1, t0
ECHANGEUR:
	beqz a5, ECHANGEUR_LIGNES
	bnez a5, ECHANGEUR_COLONNES

ECHANGEUR_LIGNES:
	jal  fnINVLIGNES   # appel de fonction
	j    SUITE_ECHANGEUR
 
ECHANGEUR_COLONNES:
	jal  fnINVCOLONNES # appel de fonction
	j    SUITE_ECHANGEUR
 
SUITE_ECHANGEUR:
	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 8

	li   a0, 0
	ret
#######################################################
#######################################################

#######################################################
################# REMPLITAB ###########################
# Arguments:
# - a0: tailleX de la matrice
# - a1: tailleY de la matrice
# - a2: addresse de la matrice a remplir
# - a3: charactere avec lequel remplir
fnREMPLITAB:
	li   t0, 0      # i

	mul  t1, a0, a1 # tailleX*tailleY

TANTQUE_REMPLTAB:
	bge  t0, t1, SUITE_REMPLTAB

	# matrice[t0]
	add  t2, t0, a2

	# matrice[t0] = a3
	sb   a3, 0(t2)
	addi t0, t0, 1
	j    TANTQUE_REMPLTAB

SUITE_REMPLTAB:
	ret
#######################################################
#######################################################

#######################################################
################ TRANSLATEX ############################
# Arguments:
# - a0: tailleX de la matrice
# - a1: tailleY de la matrice
# - a2: addresse de la matrice a translater
# - a3: addresse de la matrice temporaire de la meme taille
# - a4: nombre de pixels a translater
fnTRANSLATEX:
	bgez a4, TRANSLATE_X_POS
	bltz a4, TRANSLATE_X_NEG

TRANSLATE_X_POS:
	li   t0, 0 # i
	li   t1, 0 # j
	sub  t2, a0, a4               # tailleX - decalage
TANTQUE_TRANSLATE_X_POS:
	bge  t0, a1, FIN_TRANSLATE_X  # while(i < tailleY)
	bge  t1, t2, SUITETANTQUE_TRANSLATE_X_POS # while(j < (tailleX-decalage))

	# matrice[t0][t1]
	mul  t3, t0, a0
	add  t3, t3, t1
	add  t3, t3, a2

	# matrice_temp[t0][t1+a4]
	mul  t4, t0, a0
	add  t4, t4, t1
	add  t4, t4, a4
	add  t4, t4, a3

	# matrice_temp[t0][t1+a4] = matrice[t0][t1]
	lb   t5, 0(t3)
	sb   t5, 0(t4)
	addi t1, t1, 1
	j    TANTQUE_TRANSLATE_X_POS
SUITETANTQUE_TRANSLATE_X_POS:
	addi t0, t0, 1
	li   t1, 0
	j    TANTQUE_TRANSLATE_X_POS
	
TRANSLATE_X_NEG:
	li   t0, 0                    # i
	neg  t1, a4                   # j = abs(decalage)
TANTQUE_TRANSLATE_X_NEG:
	bge  t0, a0, FIN_TRANSLATE_X
	bge  t1, a0, SUITETANTQUE_TRANSLATE_X_NEG

	# matrice[t0][t1]
	mul  t3, t0, a0
	add  t3, t3, t1
	add  t3, t3, a2

	# matrice_temp[t0][t1-a4]
	mul  t4, t0, a0
	add  t4, t4, t1
	add  t4, t4, a4
	add  t4, t4, a3

	# matrice_temp[t0][t1-a4] = matrice[t0][t1]
	lb   t5, 0(t3)
	sb   t5, 0(t4)
	addi t1, t1, 1
	j    TANTQUE_TRANSLATE_X_NEG
SUITETANTQUE_TRANSLATE_X_NEG:
	addi t0, t0, 1
	neg  t1, a4                    # j = abs(decalage)
	j    TANTQUE_TRANSLATE_X_NEG

FIN_TRANSLATE_X:
	ret
#######################################################
#######################################################

#######################################################
################ TRANSLATEY ############################
# Arguments:
# - a0: tailleX de la matrice
# - a1: tailleY de la matrice
# - a2: addresse de la matrice a translater
# - a3: addresse de la matrice temporaire de la meme taille
# - a4: nombre de pixels a translater
fnTRANSLATEY:
	bgez a4, TRANSLATE_Y_POS
	bltz a4, TRANSLATE_Y_NEG

TRANSLATE_Y_POS:
	li   t0, 0                     # i
	li   t1, 0                     # j
	sub  t2, a0, a4                # taille - decalage
TANTQUE_TRANSLATE_Y_POS:
	bge  t1, a0, FIN_TRANSLATE_Y
	bge  t0, t2, SUITETANTQUE_TRANSLATE_Y_POS

	# matrice[t0][t1]
	mul  t3, t0, a0
	add  t3, t3, t1
	add  t3, t3, a2

	# matrice_temp[t0+a4][t1]
	add  t4, t0, a4
	mul  t4, t4, a0
	add  t4, t4, t1
	add  t4, t4, a3

	# matrice_temp[t0+a4][t1] = matrice[t0][t1]
	lb   t5, 0(t3)
	sb   t5, 0(t4)
	addi t0, t0, 1
	j    TANTQUE_TRANSLATE_Y_POS
SUITETANTQUE_TRANSLATE_Y_POS:
	addi t1, t1, 1
	li   t0, 0
	j    TANTQUE_TRANSLATE_Y_POS

TRANSLATE_Y_NEG:
	li   t1, 0                      # i
	neg  t0, a4                     # j = abs(decalage)
TANTQUE_TRANSLATE_Y_NEG:
	bge  t1, a0, FIN_TRANSLATE_Y
	bge  t0, a1, SUITETANTQUE_TRANSLATE_Y_NEG

	# matrice[t0][t1]
	mul  t3, t0, a0
	add  t3, t3, t1
	add  t3, t3, a2

	# matrice_temp[t0-a4][t1]
	add  t4, t0, a4
	mul  t4, t4, a0
	add  t4, t4, t1
	add  t4, t4, a3

	# matrice_temp[t0-a4][t1] = matrice[t0][t1]
	lb   t5, 0(t3)
	sb   t5, 0(t4)
	addi t0, t0, 1
	j    TANTQUE_TRANSLATE_Y_NEG
SUITETANTQUE_TRANSLATE_Y_NEG:
	addi t1, t1, 1
	neg  t0, a4                     # j = abs(decalage)
	j    TANTQUE_TRANSLATE_Y_NEG

FIN_TRANSLATE_Y:
	ret
#######################################################
#######################################################

#######################################################
################ TRANSLATE ############################
# Arguments:
# - a0: tailleX de la matrice
# - a1: tailleY de la matrice
# - a2: addresse de la matrice a translater
# - a3: addresse de la matrice temporaire de la meme taille
# - a4: 0 si translation sur x, 1 si translation sur y
# - a5: nombre de pixels a translater
# Retour:
# - a0: addresse du message d'erreur si la translation a echouee, 0 sinon
fnTRANSLATE:
	# ouverture
	addi sp, sp, -52
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 52

	mv   t0, a0
	mv   t1, a1
	mv   t2, a2
	mv   t3, a3

	# prologue "statique"
	sw   t0, 8(sp)
	sw   t1, 12(sp)
	sw   t2, 16(sp)
	sw   t3, 20(sp)

	# arguments
	mv   a0, t0
	mv   a1, t1
	mv   a2, t3
	li   a3, ' '
	# appel de fonction
	jal  fnREMPLITAB

	# arguments
	lw   a0, 8(sp)
	lw   a1, 12(sp)
	lw   a2, 16(sp)
	lw   a3, 20(sp)

	beqz a4, TRANSLATE_X
	bnez a4, TRANSLATE_Y

TRANSLATE_X:
	mv   a4, a5
	jal  fnTRANSLATEX
	j    FIN_TRANSLATE

TRANSLATE_Y:
	mv   a4, a5
	jal  fnTRANSLATEY
	j    FIN_TRANSLATE

FIN_TRANSLATE:
	# arguments
	lw   a0, 8(sp)
	lw   a1, 12(sp)
	lw   a2, 16(sp)
	lw   a3, 20(sp)

	# appel de fonction
	jal  fnCOPIETAB

	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 52

	li   a0, 0
	ret
#######################################################
#######################################################