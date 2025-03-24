/*
  Warnings:

  - The `genre` column on the `Produit` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `note_coeur` column on the `Produit` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `note_fond` column on the `Produit` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `note_tete` column on the `Produit` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- AlterTable
ALTER TABLE "Produit" ADD COLUMN     "dupe" TEXT,
DROP COLUMN "genre",
ADD COLUMN     "genre" TEXT[],
DROP COLUMN "note_coeur",
ADD COLUMN     "note_coeur" TEXT[],
DROP COLUMN "note_fond",
ADD COLUMN     "note_fond" TEXT[],
DROP COLUMN "note_tete",
ADD COLUMN     "note_tete" TEXT[];
