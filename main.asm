.data
tailleX:		.word 0
tailleY:		.word 0
nbCoul:			.word 0
carParCoul:		.word 0
trans:			.word 0
permutDim:	    .word 0
fich: 			.space 300
nouvFich:		.space 300
car:			.asciz "\0"
messFich:	    .asciz "Veuillez saisir le chemin absolu vers le fichier a transformer"
messRes:	    .asciz "Ou souhaitez-vous stocker le fichier resultant?"
messTrans:		.asciz "Quelle transformation souhaitez-vous faire?\n0 - Effectuer une rotation d'image\n1 - Effectuer une translation d'image\nVotre choix: "
messRot:		.asciz "Quelle rotation souhaitez-vous faire?\n0 - Rotation de 180 degres\n1 - Rotation de 90 degres\nVotre choix: "
messRotSens:	.asciz "Dans quel sens souhaitez-vous faire la rotation?\n0 - Sens trigonometrique\n1 - Sens horaire\nVotre choix: "
messRotDir:		.asciz "Dans quel sens souhaitez-vous faire la rotation?\n0 - Horizontalement\n1 - Verticalement\nVotre choix: "
messTransSens:	.asciz "Souhaitez-vous faire une translation:\n0 - Sur x\n1 - Sur y\nVotre choix: "
messTransPix:	.asciz "De combiens de pixels souhaitez-vous translater?\nVotre choix: "
messErrLect:	.asciz "L'image n'a pas pu etre lue"
messErrMode:	.asciz "Votre choix est invalide!"
messSucces:		.asciz "L'image a ete transformee avec succes!"

.text
j MAIN

# Inclusion des fonctions
.include "fonctions.asm"

MAIN:
	# ouverture
	addi sp, sp, -8
	sw   ra, 0(sp)
	sw   fp, 4(sp)
	addi fp, sp, 8

	# demande fichier source
	li   a7, 54
	la   a0, messFich
	la   a1, fich
	li   a2, 300
	ecall
	bnez a1, KILL

	la   a0, fich
	jal  fnTRIM

	# demande fichier destination
	li   a7, 54
	la   a0, messRes
	la   a1, nouvFich
	li   a2, 300
	ecall
	bnez a1, KILL

	la   a0, nouvFich
	jal  fnTRIM

	la   a0, fich
	jal  fnLITFICHIER # appel de fonction

	bnez a0, ERR_FIN # s'il y a des erreurs, on les affiche

	# calcul de "l'aire" (tailleX*tailleY) de la matrice dans s0
	mv   s0, a4

	mv   s1, a1      # copie du tableau de l'image dans s1
	
	# Allocation d'une matrice temporaire de meme taille dans s2
	li   a7, 9
	mv   a0, s0
	ecall
	mv   s2, a0

	lw   a0, tailleX
	lw   a1, tailleY
	mv   a2, s1

	jal  fnAFFICHEMATRICE

	# demander a l'utilisateur quelle transformation a faire et stockage dans trans
	li   a7, 51
	la   a0, messTrans
	li   a1, 3
	ecall
	bnez a1, KILL
	sw   a0, trans, t0

	# Switch-case en fonction du choix de l'utilisateur
SELON:
	li   t1, 0
	beq  a0, t1, ROTATION
	addi t1, t1, 1
	beq  a0, t1, TRANSLATION

	# Default: error - choix invalide
	la   a0, messErrMode
	j    ERR_FIN

ROTATION:
	# demander a l'utilisateur quelle rotation a faire
	li   a7, 51
	la   a0, messRot
	li   a1, 3
	ecall
	bnez a1, KILL
	mv   a4, a0

	sw   a4, permutDim, t0

	beqz a4, ROTATION_180
	bnez a4, ROTATION_90

ROTATION_90:
	# demander a l'utilisateur si rotation a gauche ou a droite
	li   a7, 51
	la   a0, messRotSens
	li   a1, 3
	ecall
	bnez a1, KILL
	mv   a5, a0

	j    ROTATION_SUITE

ROTATION_180:
	# demander a l'utilisateur si rotation a gauche ou a droite
	li   a7, 51
	la   a0, messRotDir
	li   a1, 3
	ecall
	bnez a1, KILL
	mv   a5, a0

	j ROTATION_SUITE

ROTATION_SUITE:
	lw   a0, tailleX
	lw   a1, tailleY
	mv   a2, s1
	mv   a3, s2

	# appel de fonction
	jal  fnROTATE

	lw   t0, permutDim
	beqz t0, SUITE_ROTATION

PERMUT_DIM:
	lw   t0, tailleX
	lw   t1, tailleY
	sw   t1, tailleX, t2
	sw   t0, tailleY, t2

SUITE_ROTATION:
	# pas d'erreurs
	li   a0, 0

	j    APRES_TRANSFORMATION

TRANSLATION:
	# demander a l'utilisateur quelle translation a faire
	li   a7, 51
	la   a0, messTransSens
	li   a1, 3
	ecall
	bnez a1, KILL
	mv   a4, a0

	# demander a l'utilisateur de combien de pixels translater
	li   a7, 51
	la   a0, messTransPix
	li   a1, 3
	ecall
	bnez a1, KILL
	mv   a5, a0
	
	lw   a0, tailleX
	lw   a1, tailleY
	mv   a2, s1
	mv   a3, s2

	# appel de fonction
	jal  fnTRANSLATE

	# pas d'erreurs
	li   a0, 0

	j    APRES_TRANSFORMATION

APRES_TRANSFORMATION:
	beqz a0, FIN        # s'il n'y a pas d'erreurs, finaliser

	j    ERR_FIN

FIN:
	la   a0, fich
	la   a1, nouvFich
	# calcul du nombre de lignes a copier dans a2
	lw   a5, tailleX  
	lw   a6, tailleY
	mv   a4, s1
	lw   a2, nbCoul
	lw   a3, carParCoul
	
	jal  fnECRITFICHIER

	bnez a0, ERR_FIN    # s'il y a des erreurs, on les affiche
	
	lw   a0, tailleX
	lw   a1, tailleY
	mv   a2, s1

	jal  fnAFFICHEMATRICE

	li   a7, 55
	la   a0, messSucces
	li   a1, 1
	ecall

	li a0, 0
ERR_FIN:
	beqz a0, KILL        # s'il n'y a pas d'erreurs, terminer le programme

	# Afficher le message d'erreur
	li   a7, 55
	li   a1, 0
	ecall
	
KILL:
	# fin
	lw   ra, 0(sp)
	lw   fp, 4(sp)
	addi sp, sp, 8
	
	li   a7, 10
	ecall
