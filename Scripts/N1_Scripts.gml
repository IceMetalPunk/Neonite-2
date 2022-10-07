#define ds_list_wrandom
/* Syntax: ds_list_weighted_random(list)

Arguments:
list - A ds_list where every odd entry (1, 3, 5, 7, 9, etc.) is a weight for the entry value
       before it.

Returns: A random entry value (not a weight).

*/
var total,list,val,p,size;
list=argument0;
size=ds_list_size(list)/2;

total=0;
for (p=0; p<size; p+=1) {
total+=ds_list_find_value(list,2*p+1);
}

val=random(total);

total=0;
for (p=0; p<size; p+=1) {
total+=ds_list_find_value(list,2*p+1);
if (total>=val) { return ds_list_find_value(list,2*p); }
}

return -1;

#define sfx_volume
var list,p,sound;
list=ds_list_create();
ds_list_add(list,capture_sfx);
ds_list_add(list,blip_sfx);

for (p=0; p<ds_list_size(list); p+=1) {
sound=ds_list_find_value(list,p);
sound_volume(sound,argument0);
}

#define file_bin_write_double
/*
**  Usage:
**      encode_real_double(n)
**
**  Arguments:
**      n       a real value
**
**  Returns:
**      an 8-byte character string in IEEE 754 double precision format
**
**  GMLscripts.com
*/
{
    var n,str,c,byte,E,M,f,i;
    n = argument1;
    f=argument0;
    if (n == 0) {
        repeat(8) { file_bin_write_byte(f,0); }
        return false;
    }
    byte[0] = 0;
    byte[7] = 0;
    if (n < 0) {
        n *= -1;
        byte[7] = byte[7] | $80;
    }
    E = floor(log2(n));
    M = n / power(2,E) - 1;
    E += 1023;
    var i;
    i = 0;
    while (i < 11) {
        if (i < 4) {
            byte[6] = byte[6] | ((E & (1<<i)) << 4);
        }
        else {
            byte[7] = byte[7] | ((E & (1<<i)) >> 4);
        }
        i += 1;
    }
    i = 51;
    while (i >= 0) {
        M *= 2;
        if (M >= 1) {
            byte[i div 8] = byte[i div 8] | (1<<(i mod 8));
            M -= 1;
        }
        i -= 1;
    }
    str = "";
    for (i = 7; i >= 0; i -= 1) {
        str += chr(byte[i]);
    }

    for (i=1; i<=string_length(str); i+=1) {
    file_bin_write_byte(f,ord(string_char_at(str,i)));
    }
    return true;
}

#define file_bin_read_double
/*
**  Usage:
**      decode_real_double(str)
**
**  Arguments:
**      str     an 8-byte string in IEEE 754 double precision format
**
**  Returns:
**      a real value
**
**  GMLscripts.com
*/
{
    var str,i,S,E,M,byte,n,f;
    f = argument0;
    
    str="";
    repeat(8) {
    str+=chr(file_bin_read_byte(f));
    }
    
    var i;
    for (i = 0; i < 8; i += 1) {
        byte[i] = ord(string_char_at(str,8 - i));
    }
    S = 1 - 2*((byte[7] & $80) > 0);
    i = 0;
    M = 0;
    while (i <= 51) {
        if (byte[i div 8] & (1<<(i mod 8)) > 0) {
            M += 1;
        }
        M /= 2;
        i += 1;
    }
    i = 62;
    E = 0;
    while (i > 51) {
        E *= 2;
        if (byte[i div 8] & (1<<(i mod 8)) > 0) {
            E += 1;
        }
        i -= 1;
    }
    if (E == 0) {
        n = S * M * power(2, -1022);
    }
    else {
        n = S * (M + 1) * power(2, E - 1023);
    }
    return n;
}

#define highscores_save
/* Syntax: highscores_save()

Arguments:
(None)

Returns: Nothing

Notes: Saves the highscores list to a local file.

*/
var p,f,v;
f=file_bin_open(program_directory+"\scores.nsf",1);
file_bin_rewrite(f);

for (p=ds_list_size(global.highscores)-1; p>=0; p-=1) {
/*repeat(100) {
file_bin_write_byte(f,irandom(255));
}*/

v=ds_list_find_value(global.highscores,p);
file_bin_write_double(f,v);
v=ds_list_find_value(global.highnames,p);
file_bin_write_string(f,v);

}

/*repeat(100) {
file_bin_write_byte(f,irandom(255));
}*/

file_bin_close(f);

return 1;

#define highscores_load
/* Syntax: highscores_load()

Arguments:
(None)

Returns: 1 on success, 0 if no highscores have been saved.

Notes: Loads the highscores list from a local file.

*/
var p,f,v;

if (!file_exists(program_directory+"\scores.nsf")) { return false; }

f=file_bin_open(program_directory+"\scores.nsf",0);

ds_list_clear(global.highscores);
ds_list_clear(global.highnames);

while (file_bin_position(f)<file_bin_size(f)) {

v=file_bin_read_double(f);
ds_list_add(global.highscores,v);
v=file_bin_read_string(f);
ds_list_add(global.highnames,v);

}

file_bin_close(f);

return 1;

#define file_bin_write_string
/* Syntax: file_bin_write_string(f,string)

Arguments:
f - The file to write to.
string - The string to write (cannot contain null bytes)

Returns: Nothing

Notes: Writes a null-terminated string to a file.
*/
var f,str,p;
f=argument0;
str=argument1;

for (p=1; p<=string_length(str); p+=1) {
file_bin_write_byte(f,ord(string_char_at(str,p)));
}
file_bin_write_byte(f,0);

return 1;

#define file_bin_read_string
/* Syntax: file_bin_read_string(f)

Arguments:
f - The file to write to.

Returns: The value of a read null-terminated string.

Notes: Reads a null-terminated string from a file.
*/
var f,str,p,b;
f=argument0;
str="";

show_debug_message("BEGIN READ STR");
b=file_bin_read_byte(f);
while (b!=0 and file_bin_position(f)<file_bin_size(f)) {
str+=chr(b);
b=file_bin_read_byte(f);
}

return str;

#define highscores_sort
/* Syntax: highscores_sort()

Arguments:
(None)

Returns: Nothing

Notes: Sorts highscores and names to match.

*/
var l1,l2,v1,v2,p,swapped;

l1=global.highnames;
l2=global.highscores;

swapped=true;

while (swapped) {

swapped=false;
for (p=min(ds_list_size(l1),ds_list_size(l2))-1; p>0; p-=1) {

v1=ds_list_find_value(l2,p);
v2=ds_list_find_value(l2,p-1);

if (v1<v2) {
ds_list_replace(l2,p,v2);
ds_list_replace(l2,p-1,v1);

v1=ds_list_find_value(l1,p);
v2=ds_list_find_value(l1,p-1);

ds_list_replace(l1,p,v2);
ds_list_replace(l1,p-1,v1);

swapped=true;
}

}
}

return 1;

