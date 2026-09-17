/*
  Warnings:

  - Added the required column `updatedAt` to the `DownloadToken` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "DownloadToken" ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;

-- CreateIndex
CREATE INDEX "Review_moderatedById_idx" ON "Review"("moderatedById");

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_moderatedById_fkey" FOREIGN KEY ("moderatedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
