%let ruta=C:\Users\Jose\Desktop\sas\Entrada\input;

%macro validar_ficheros();
	/*tabla de errores al cargar */
	data erroresficheros;
		fehacarga=today();
		motivo="No se carga el fichero porque no tiene la fecha bien";
		fichero="CBC_06092011.txt";
		format fehacarga date9.;
	run;

	*guardamos los ficheros en la tabla archivos;
	data archivos;
		rc=filename('dir',"&ruta");
		dirid=dopen('dir');
		numarchivos=dnum(dirid);
		do i=1 to numarchivos;
		nombrearchivos=dread(dirid,i);
		output;
		end;
		rc=close(dirid);
		drop rc i;
	run;
	*validar los nombres
	dos salidas;
	data archivos tablatemporal;
		set archivos;
		nombre=substr(nombrearchivos,3,1);
		if nombre = 'C' then output archivos;
		else if nombre ='D' then output archivos;
		else if nombre= 'J' then output archivos;
		drop dirid numarchivos;
		*si no coinciden los nombres dara salida en tablatemporal;
		if nombre not in ('C','D','J') then output tablatemporal;
	run;
	
	data tablatemporal;
		set tablatemporal;
		rename nombrearchivos=fichero;
		fehacarga= today();
		format fehacarga date9.;
		motivo="se rechaza fichero por no cumplir validacion de nombre";
		drop nombre;
	Run;

		proc append data= tablatemporal base=erroresficheros force;
run;	
			
	  

	data fechasvalidas tablatemporal;
		set archivos (drop=nombre);
		*cortar variable llamada fecha;
		fecha=substr(nombrearchivos,5,8);
		*transformar fechanueva a numerico y decirle a sas como leerla;
		fechanueva=input(fecha,ddmmyy8.);
		*decir a sas como mostrar la fecha;
		format fechanueva date9.;
		*Fechahoy con la funcion today nos da el mes en curso(pero necesitamos el principio);
		fechahoy= today();
		format fechahoy date9.;
		fechahoy=intnx('month', today(), 0, 'b'); 
		if fechanueva = fechahoy then output fechasvalidas;
		else output tablatemporal;

	run;


	data tablatemporal;
		set tablatemporal (rename=(nombrearchivos=fichero));
		
		fehacarga= today();
		format fehacarga date9.;
		motivo="se rechaza fichero por no cumplir validacion de fecha";
		keep fehacarga motivo fichero;
	run;


		 proc append data=tablatemporal base=erroresficheros force;
	run;


	proc sort data=fechasvalidas;
		by fechanueva;
	run;
*se añade un contador a la variable fecha nueva,cuando este cambie se reseteara el contador;
	data fechasconteo; 
		set fechasvalidas;
		drop fechanueva fechahoy;
		if _n_=1 then count=1;
		else count +1;	
	run;
		*ordenamos fechas conteo de manera descendente para que el primer valor sea el mas alto;
	proc sort data=fechasconteo;
		by descending count;
	run;

*_N_=1 primer valor de la tabla;
	data tablatemporal;
		set fechasconteo;
		if _N_=1 and count eq 3 then output;		
	run;

	data _null_;
	set tablatemporal;
		/*asi sacamos la variable de una tabla en una macrivariable*/
		call symput ("num_fich",count);
		/*call sumput('nombre de macrovar',variable de la tabla);*/
	run;
	%put &num_fich;
	/*con &nobre_macrovariable utilizamos lo que contiene dentro de la macro*/
	%if &num_fich = 3 %then %do;
*cargar archivos;
		data xxc;
			infile "C:\Users\Jose\Desktop\sas\Entrada\input\CBC_01072016.txt" DSD DLM='09'x MISSOVER;
			input fecha nombre$ id$ saldo$;
			informat fecha date9.;
			format fecha date9.;
			if fecha ne . and nombre ne '' and id ne '' and saldo ne '';
		run;

		data xxd;
			infile "C:\Users\Jose\Desktop\sas\Entrada\input\CBD_01072016.txt" DSD DLM='09'x MISSOVER;
			input fecha id$ saldo$ tipo_correcion$;
			informat fecha date9.;
			format fecha date9.;
			if fecha ne . and id ne '' and saldo ne '' and tipo_correcion ne '';
			if id=01 and saldo<0 then delete;
		run;
		
		data xxj;
			infile "C:\Users\Jose\Desktop\sas\Entrada\input\CBJ_01072016.txt" DSD DLM='09'x MISSOVER;
			input fecha id$ saldo$ tipo_correcion$;
			informat fecha date9.;
			format fecha date9.;
			if fecha ne . and id ne '' and saldo ne '' and tipo_correcion ne '';
			if id=01 and saldo<0 then delete;
		run;

		proc sort data=xxc;
			by id;
		run;

			proc sort data=xxd;
			by id;
		run;

			proc sort data=xxj;
			by id;
		run;
*agrupar por id;
		data xxcid (drop=saldo saldo1);
			set xxc;
			by id;
			saldo1=input(saldo,8.);
			*se crea una variable nueva que se arrastre sin resetearse cada vez que lea una linea;
			retain sumsaldo;
			*en la primera id va a rellenar sumsaldo con la casilla saldos;
			if first.id then sumsaldo=saldo1;
			*para todo lo demas va a rellenar sumsaldo con la suma de sumsaldo y saldos;
			else sumsaldo= sum(sumsaldo,saldo1);
			*nos quedamos con el ultimo valor y su suma;
			if last.id then output;
		run;


		data xxdid (drop= saldo saldo1);
			set xxd;
			by id;
			saldo1=input(saldo,8.);
			*se crea una variable nueva que se arrastre sin resetearse cada vez que lea una linea;
			retain sumsaldo;
			*en la primera id va a rellenar sumsaldo con la casilla saldos;
			if first.id then sumsaldo=saldo1;
			*para todo lo demas va a rellenar sumsaldo con la suma de sumsaldo y saldos;
			else sumsaldo= sum(sumsaldo,saldo1);
			*nos quedamos con el ultimo valor y su suma;
			if last.id then output;
		run;

		data xxjid (drop= saldo saldo1);
			set xxj;
			by id;
			saldo1=input(saldo,8.);
			*se crea una variable nueva que se arrastre sin resetearse cada vez que lea una linea;
			retain sumsaldo;
			*en la primera id va a rellenar sumsaldo con la casilla saldos;
			if first.id then sumsaldo=saldo1;
			*para todo lo demas va a rellenar sumsaldo con la suma de sumsaldo y saldos;
			else sumsaldo= sum(sumsaldo,saldo1);
			*nos quedamos con el ultimo valor y su suma;
			if last.id then output;
		run;
libname tablas"C:\Users\Jose\Desktop\sas\Entrada\tablas_sas";

		data tablas.xxc;
			set xxcid;
		run;
		data tablas.xxd;
			set xxdid;
		run;
		data tablas.xxj;
			set xxjid;
		run;


		data correciones(drop= nombre);
			set tablas.xxc tablas.xxd tablas.xxj;
			
		run;

		
		proc sort data=correciones;
			by id;
		run;

		data correciones(drop=sumsaldo);
			set correciones;
			by id;
			retain saldo;
			if first.id then saldo=(sumsaldo);
			else saldo=sum(sumsaldo, saldo);
			if last.id then output;
		run;

		data movimientos;
			set xxc xxd xxj;
			*condicion, entonces se rellena variable con ori;
			if tipo_correcion = '' then tipo_correcion='ori';
		run;
	%end;
	

%mend validar_ficheros;

%validar_ficheros();

    a = 'cat'; 
      put 'a=' a; 

      substr(a,2,1) = 'o'; 
      put 'a=' a; 

      substr(a,1,1) = 'd'; 
      put 'a=' a; 

      substr(a,3,1) = 'g'; 
      put 'a=' a; 
      b = a; 
*a variable que quiero pasar
substr(variable que quiero leer y cortar);
data hola;
   a = 'cat'; 
   
andrei=substr(a,1,1);
run;

data ejemplo;
format x y z date9.;
y="12JUN08"d;
*ULTIMO DÍA DEL MES EN FUNCION DE LA FECHA;
x=intnx("month",y,1);
put x;
*PRIMER DÍA DEL MES EN FUNCION DE LA FECHA;
z=intnx("month",y,0);
put z=;
run;


data ejemplo(keep=Region Sales);
set sashelp.shoes;
run;

proc sort data=ejemplo;
by Region Sales;
run;

data agrupado;
	set ejemplo;
	by region ;
	retain agrupado_sales;
	if first.region then agrupado_sales=Sales;
	else agrupado_sales=sum(agrupado_sales,Sales);
	if last.region then output;
run;
