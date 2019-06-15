#include "wht.bi"
#include "vecops3.bas"
#include "file.bi"
type xhnet
	veclen as ulong
	density as ulong
	depth as ulong
	ln2 as ulong
	weights(any) as single
	workA(any) as single
	workB(any) as single
	declare sub init(veclen as ulong,density as ulong,depth as ulong)
	declare sub recall(result as single ptr,inVec as single ptr)
	declare sub memsize()
	declare function load(filename as string) as integer
	declare function save(filename as string) as integer
end type

sub xhnet.init(veclen as ulong,density as ulong,depth as ulong)
	this.veclen=veclen
	this.density=density
	this.depth=depth
	this.ln2=log(veclen)/log(2)
	memsize()
	randomize()
	for i as ulong=0 to ubound(weights)
		weights(i)=2*rnd()-1
	next
end sub

sub xhnet.memsize()
	redim workA(veclen-1)
	redim workB(veclen-1)
	redim weights(3*veclen*density*depth-1)
end sub

sub xhnet.recall(result as single ptr,inVec as single ptr)
	dim as single ptr wts=@weights(0),wa=@workA(0),wb=@workB(0)
	dim as single sc=2!/sqr(veclen*density)
	adjust(wa,inVec,sc,veclen)
	dim as ulong i
	do
		zero(result,veclen)
		for j as ulong=0 to density-1
			multiply(wb,wa,wts,veclen):wts+=veclen
			fht_float(wb,ln2)
			switch(result,wb,wts,veclen):wts+=2*veclen
		next
		i+=1
		if i=density then exit do
		scale(wa,result,sc,veclen)
	loop
end sub
		
'returns 0 on success   
function xhnet.save(filename as string) as integer
   dim as integer e,f
   f=freefile()
   open filename for binary access write as #f
   e or=put( #f,,veclen)
   e or=put( #f,,density)
   e or=put( #f,,depth)
   e or=put( #f,,ln2)
   e or=put( #f,,weights())
   close #f
   return e
end function
 
'returns 0 on success
function xhnet.load(filename as string) as integer
   dim as integer e,f
   f=freefile()
   open filename for binary access read as #f
   e or=get( #f,,veclen)
   e or=get( #f,,density)
   e or=get( #f,,depth)
   e or=get( #f,,ln2)
   memsize()
   e or=get( #f,,weights())
   close #f
   return e
end function

sub presentData(array as single ptr,x as ulong,y as ulong,edge as ulong)
dim as ulong idx
for j as ulong=0 to edge-1
for i as ulong=0 to edge-1
	dim as single r=array[idx]:idx+=1
	dim as single g=array[idx]:idx+=1
	dim as single b=array[idx]:idx+=2
	if(r>1!) then r=1!
	if(g>1!) then g=1!
	if(b>1!) then b=1!
	if(r<-1!) then r=-1!
	if(g<-1!) then g=-1!
	if(b<-1!) then b=-1!
	r=r*127.5!+127.5
	g=g*127.5!+127.5
	b=b*127.5!+127.5
	pset (i+x,j+y),RGB(r,g,b)
next
next
end sub


type mutator
	as ulongint positions(any)
	as single values(any),prec
	declare sub init(size as ulong,precision as single)
	declare sub mutate(x() as single)
	declare sub undo(x() as single)
end type

sub mutator.init(size as ulong,precision as single)
	redim positions(size-1),values(size-1)
	prec=precision
	randomize()
end sub

sub mutator.mutate(x() as single)
	for i as ulong=0 to ubound(positions)
		dim as ulong idx=int(rnd()*(ubound(x)+1))
		positions(i)=idx
		dim as single v=x(idx)
		values(i)=v
		dim as single mut=2!*exp(-prec*rnd())
		if rnd()<0.5 then mut=-mut
		mut+=v
		if mut>1! then mut=v
		if mut<-1! then mut=v
		x(idx)=mut
	next
end sub

sub mutator.undo(x() as single)
	for i as long=ubound(positions) to 0 step -1
		x(positions(i))=values(i)
	next
end sub

const as string IMG_FILE="imgdata.dat"
const as string NET_FILE="net7.dat"
const edge=32

screenres 400,400,32
dim as ulong size=4*edge*edge
dim as integer ff=freefile()
dim as long count,iter,rcount
open IMG_FILE for binary access read as #ff
get #ff,,count
dim as single imgData(count*size-1)
get #ff,,imgData()
close #ff
presentData(@imgData(0),100,100,edge)
dim as single work(size-1),parentCost=1!/0!
dim as boolean te,re,ne
dim as mutator mut
mut.init(25,25)
dim as xhnet net
net.init(size,2,5)
if fileExists(NET_FILE)  then net.load(NET_FILE)
do
  var k=inkey()
  if (k="t") or (k="T") then
   te=true
   re=false
   ne=false
  end if
  if (k="r") or (k="R") then
    te=false
    re=true
    ne=false
  end if 
  if (k="n") or (k="N") then
    te=false
    re=false
    ne=true
  end if 
  if (k="s") or (k="S") then
    te=false
    re=false
    ne=false
  end if 
  if k=chr(27) then 
    net.save(NET_FILE)
	exit do
  end if	
  if not (te or re or ne) then
   cls
   draw string (5,20),"T to Train, R to Recall, S to Stop, Esc to Quit"
   sleep 300
  end if
  if te then
	cls
	draw string (20,20),"Training    Cost:"+Str(parentCost)+"   Iter:"+Str(iter)
	dim as single childcost
	mut.mutate(net.weights())
	for i as ulong=0 to count-1
		net.recall(@work(0),@imgData(i*size))
		childcost+=errorl2(@work(0),@imgData(i*size),size)
	next
	if childcost<parentCost then
	  parentCost=childcost
	else
	  mut.undo(net.weights())
	end if
	iter+=1
  end if
  if re then
    cls
    draw string (20,20),"Recall"
     net.recall(@work(0),@imgData(rcount*size))
	 presentData(@work(0),100,100,edge)
	 sleep(2000)
	 rcount+=1
	 if rcount=count then rcount=0
  end if
  
  if ne then
    cls
    draw string (20,20),"Recall from Noise"
    for i as ulong=0 to ubound(work)
       work(i)=2!*rnd()-1!
     next
     net.recall(@work(0),@work(0))
	 presentData(@work(0),100,100,edge)
	 sleep(2000)
  end if
loop
