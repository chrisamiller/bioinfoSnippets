## A rough filter for removing germline variants from impure tumor samples
##
## takes the following arguments:
##
## arg 1 = filename
## arg 2 = position of column containing tumor reference-supporting reads
## arg 3 = position of column containing tumor variant-supporting reads
##
## outputs the same file with two trailing columns:
## 1) whether the variant is more likely to be heterozygous (50%) or homozygous (100%) "het" or "hom"
## 2) a p-value corresponding to whether the site is significantly different from that designation
##

args <- commandArgs(trailingOnly = TRUE)

b = read.table(args[1],skip=1,sep="\t")

pval=c();
type=c();
for(i in 1:length(b$V3)){
  reads=(b[i,args[2]]+b[i,args[3]]);
  het=round(reads/2)
  hetmat = matrix(c(b[i,args[2]], het, b[i,args[3]], het),nrow=2)
  hommat = matrix(c(b[i,args[2]], 0, b[i,args[3]], reads),nrow=2)

  p.het=fisher.test(hetmat)$p.value
  p.hom=fisher.test(hommat)$p.value

  if(p.het > p.hom){
    pval=c(pval,p.het)
    type=c(type,"het")
  } else {
    pval=c(pval,p.hom)
    type=c(type,"hom")
  }
}

b = cbind(b,type)
b = cbind(b,pval)
b = cbind(b,p.adjust(b$pval,method="BY"))

write.table(b,paste(args[1],".pval",sep=""),row.names=F,col.names=F,quote=F,sep="\t")
