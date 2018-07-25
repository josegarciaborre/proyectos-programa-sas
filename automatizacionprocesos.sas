
%macro validar_dni();
* se carga la tabla personas;
	data personas;
		
		infile "C:\Users\Jose\Desktop\sas\Ejercicios sas\curso\personas.csv" dlm=',' dsd missover;
		length dni$ 10;
		length fecha$ 9;
		length apellido$ 11;
		length nombre$ 17;
		input nombre$ apellido$ dni$ fecha$;
	run;
* se importa el fichero nuevos_trabajadores;
		proc import datafile="C:\Users\Jose\Desktop\sas\Ejercicios sas\curso\neuvos_trabajadores.xlsx" dbms=xlsx out=nuevos_trabajadores
	replace;
	run;
* se importa el fichero sectores_trabajo;
	proc import datafile="C:\Users\Jose\Desktop\sas\Ejercicios sas\curso\salarios.xlsx" dbms=XLSX out=Sectores_trabajo
		replace;
		sheet="Sectores_trabajo";
		getnames=yes;
	run;

	* se filtra para que no haya datos en blanco y se añade una nueva variable con la fecha de hoy y otra para calcular en la siguiente tabla la edad de las personas;
	data personas(drop= fecha rename=(fechabuena=fecha)) ;
		set personas;
		fechultimod=today();
		fecha1=input(fecha,date9.);
		format fecha1 date9.;
		format fechultimod date9.;
		fechabuena=input(fecha,date9.);
		format fechabuena date9.;
		if nombre ne'' and apellido ne '' and dni ne '' and fecha ne '';
	run;
	* se renombra el sector por sector del trabajo para combinarlo mas adelante y se filtra;
	data nuevos_trabajadores(rename=(Sector=Sector_del_Trabajo));
		set nuevos_trabajadores;
		if nombre ne '' and apellido ne'' and dni ne '' and fecha_de_nacimiento ne'.' and sector ne'';
	run;

* se ordena la tabla personas por nombre;
	proc sort data= personas;
		by dni;
	run;
	
* se ordena la tabla nuevos trabajadores por el sector del trabajo ;
	proc sort data= nuevos_trabajadores;
		by Sector_del_Trabajo;
	run;
	* se concatena la tabla sectores trabajo con nuevos_trabajadores quedandonos solo con sector del trabajo y sueldomedio;
	data sectores_trabajo (keep=Sector_del_Trabajo Sueldo_Medio);
		set sectores_trabajo nuevos_trabajadores;
	run;

	proc sort data= nuevos_trabajadores;
		by dni;
	run;
* se eliminan duplicados de la tabla sector del trabajo;
	proc sort data=sectores_trabajo nodupkeys;
		by Sector_del_Trabajo;
	run;
*se combina la tabla de personas con nuevos trabajadores, eliminando sector del trabajo, sueldo medio y fecha de nacimiento;
	data personasnuevas duplicados;
		merge personas(in=a) nuevos_trabajadores (in=b rename=(Fecha_de_nacimiento=fecha)drop=Sueldo_medio Sector_del_Trabajo );
		by dni;
		if fechultimod=. then fechultimod=today();
		format Nombre $17.;
		format apellido $11.;
		if  a and  not b  then  output personasnuevas;
		if not a and b then otuput personasnuevas;
		if a and b then output duplicados;
	run;
	
	proc sort data=duplicados out=dnibuenos nodupkeys;
		by dni;
	run;
	
	data personasnuevas;
		set personasnuevas duplicados;
	run;

	data personasnuevas;
		set personasnuevas;
		if fecha1=. then fecha1=fecha;
	run;


* se produce validacion de dni y calcula  la edad de las personas;
	data validar_dni_ (drop= numeros primera_letra f1 fecha1);
		set personasnuevas;
		numeros=input(numeros,8.);		
		numeros=substr(dni,2,8);		
		primera_letra=lowcase(substr(dni,1,1));
		ultimaletra=lowcase(substr(dni,10,1));
		f1=today();
		format f1 date9.;
		diferenage=intck("year",fecha1,f1);
		if primera_letra =>'a' and primera_letra=<'z' and numeros ne'.'  and ultimaletra=>'a' and ultimaletra=<'z' then output;
		
	run;

	
	*recordar pasar a minusculas toda la palabra;

* se crean tres tablas, una con mayores de edad, otra con menores de edad y otra con extrajeros ;
	data mayores(drop=ultimaletra) menores(drop=ultimaletra) tabla_etr(drop=ultimaletra diferenage);
		set validar_dni_ ;
		if diferenage <18 then output menores;
		else if diferenage =>18 then output mayores;
		if ultimaletra= 'x' then output tabla_etr;
	run;

	proc sort data=mayores nodup;
		by dni;
	run;

* se añade en esta tabla el campo origen con el valor extranjero;
	data tabla_etr;
		set tabla_etr;
		origen='extranjeros';
	run;
	* se importa el archivo personas_revisiones;
	proc import datafile="C:\Users\Jose\Desktop\sas\Ejercicios sas\curso\salarios.xlsx" dbms=XLSX out=personas_revisiones
		replace;
		sheet="personas_revisiones";
		getnames=yes;
	run;
*falta quitar las letras;
	* se eliminan campos vacios, se añade la diferencia de edad y se eliminan las columnas vacias e f g h i
	si la diferencia de edad es mas de 5 años la  ultima revision salarial sera hoyh;
	data personas_revisiones;
		set personas_revisiones;
		f1=today();
		format f1 mmddyy10.;
		diferencia_age=intck("year",Ultima_Revision_Salarial,f1);
		if DNI ne '' and Fecha_Nacimiento ne '.' and Sector_del_Trabajo ne '' and Ultima_Revision_Salarial ne '.' ;
		if diferencia_age >5 then Ultima_Revision_Salarial=today();
		drop e f g h i ;

	run;
	*se ordena la tabla personas revisiones por dni ;
	proc sort data= personas_revisiones;
		by dni;
	run;
/*como sacar todos los datos de una columna
	proc sql noprint;
	select diferencia_age into: var1 separated by ","
	from personas_revisiones;
	quit;
	%put &var1;*/
*se ordena la tabla validar dni por dni ;
	proc sort data= validar_dni_;
		by dni;
	run;
	* se combinan la tabla validar dni con personas revisiones;
	data trabajadores;
		merge validar_dni_(in=a) personas_revisiones(in=b);
		by dni;		
		if a and b then output;		
	run;
	* en la tabla de trabajadores si son menores de 18 el sector del trabajo es no aplica.;
	data trabajadores;
		set trabajadores;
		if diferenage <18 then Sector_del_Trabajo='no aplica';
	run; 
*se importa el archivo salario mensual;
	proc import datafile="C:\Users\Jose\Desktop\sas\Ejercicios sas\curso\Salario_mensual.xlsx" dbms=XLSX out=Salario_mensual
		replace;
	run;
	*se ordena la tabla mayores por dni;
	proc sort data=mayores;
		by dni;
	run;
*se ordena la tabla salario mensual por dni y se eliminan las columgas fghi;
	proc sort data=salario_mensual(drop=f g h i);
		by dni;
	run; 
	*se une la tabla mayores con salario mensual y personas revisiones para crear ganancias anuales;
	data ganancias_anuales;
		merge mayores(in=a) salario_mensual(in=b) personas_revisiones(in=c);
		by dni;
		if a and b and c then output;
		
	run;
* se ordena la tabla ganancias anuales por dni para agrupar en el siguiente paso.;
	proc sort data=ganancias_anuales;
		by dni;
	run;
*se crea un contador para sumar el sueldo de mes en mes y saber el total, quedandonos solo con el ultimo;
	data ganancias_anuales;
		set ganancias_anuales (keep=nombre Ultima_Revision_Salarial apellido dni sueldo Sector_del_Trabajo);
		by dni;
		retain sueldo;
		if first.dni then sueldosuma=sueldo;
		else if not first.dni then sueldosuma=sueldosuma+sueldo;
		else if last.dni then sueldosuma+sueldo;
		if last.dni then output;

	run;
	* en esta misma tabla si la ultima revision es hoy la suma del sueldo se le añadira un 20%;
	 data ganancias_anuales;
	 	set ganancias_anuales;
		if Ultima_Revision_Salarial=today() then sueldosuma=0.20*sueldosuma+sueldosuma;
	run;

	proc sort data=ganancias_anuales;
		by Sector_del_Trabajo;
	run;

	data desvio;
		merge sectores_trabajo(in=a) ganancias_anuales(in=b);
		by Sector_del_Trabajo;
		if a and b then output;
	run;
	
	data desvio;
		set desvio;
		sueldomedioanual=sueldo_medio*12;
		diferencia=sueldomedioanual-sueldosuma;
		if Sector_del_Trabajo='Abogada' and sueldosuma>sueldomedioanual then output;
		if Sector_del_Trabajo='Construcion' and sueldosuma>sueldomedioanual then output;
		if Sector_del_Trabajo='Limpieza' and sueldosuma>sueldomedioanual then output;
		if Sector_del_Trabajo='Oficina' and sueldosuma>sueldomedioanual then output;
		
	run;


proc sql;
	create table trabajadoresmayores as
	select distinct a.*
	from  nuevos_trabajadores as a inner join mayores as b
	on a.dni= b.dni;
	quit;

	proc sql;
		create table salariostrabajadoresnuevos as
		select Nombre,Apellido,DNI,Fecha_de_nacimiento,a.Sector_del_Trabajo, b.Sueldo_medio
		from trabajadoresmayores  as a inner join sectores_trabajo as b
		on b.Sector_del_Trabajo = a.Sector_del_Trabajo ;
		quit;

		data salariostrabajadoresnuevos(drop=i);
			set salariostrabajadoresnuevos;
			format meses MONYY7.;
			do i=1 to 12;
			meses=mdy(I,1,2016);output;
			end;
		run;

proc sql;	
   insert into salario_mensual
   select dni,meses,Sector_del_Trabajo,'-' as trabajo,Sueldo_medio as sueldo from salariostrabajadoresnuevos;
quit;
proc sort data=trabajadores;
	by dni;
run;

proc sort data=nuevos_trabajadores;
	by dni;
run;

data trabajadorescruce(drop=fecha ultimaletra diferenage Sueldo_medio f1 diferencia_age) trabajadoresbuena(keep=dni apellido nombre fechultimod Fecha_Nacimiento Sector_del_Trabajo  Ultima_Revision_Salarial);
	merge trabajadores(in=a) nuevos_trabajadores(in=b);
	by dni;
	if a and b then output trabajadorescruce;
	if a and not b then output trabajadoresbuena;
run;

data nuevos_trabajadores;
	length nombre $ 17 apellido $ 11;
	set nuevos_trabajadores(rename=Fecha_de_nacimiento=Fecha_Nacimiento drop=sueldo_medio);
	Ultima_Revision_Salarial=today();
	format Ultima_Revision_Salarial MMDDYY10. fechultimod date9.;
	fechultimod=today();


run;
proc append base=trabajadoresbuena data=nuevos_trabajadores ;
run;



%mend;


%validar_dni;
data ejemplo;
a='beedddd';
resultado=substr(a,1,1);
run;

	
