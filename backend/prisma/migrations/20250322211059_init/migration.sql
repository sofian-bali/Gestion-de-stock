-- CreateTable
CREATE TABLE "Produit" (
    "id" SERIAL NOT NULL,
    "code_barres" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "quantite" INTEGER NOT NULL,
    "date_ajout" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Produit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MouvementStock" (
    "id" SERIAL NOT NULL,
    "type" TEXT NOT NULL,
    "quantite" INTEGER NOT NULL,
    "date_mouvement" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "produitId" INTEGER NOT NULL,

    CONSTRAINT "MouvementStock_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Produit_code_barres_key" ON "Produit"("code_barres");

-- AddForeignKey
ALTER TABLE "MouvementStock" ADD CONSTRAINT "MouvementStock_produitId_fkey" FOREIGN KEY ("produitId") REFERENCES "Produit"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
