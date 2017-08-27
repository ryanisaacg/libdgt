module dgt.stb_image;

import dgt.io;
import core.stdc.stdio, core.stdc.string, core.stdc.stdlib;

static immutable STBI_ORDER_RGB = 0;
static immutable STBI_ORDER_BGR = 1;
static immutable FAST_BITS = 9;

struct stbi_io_callbacks 
{
    int function(void*, char*, int) read;
    void function(void*, uint) skip;
    int function(void*) eof;
}

struct stbi__context
{
   uint img_x, img_y;
   int img_n, img_out_n;

   stbi_io_callbacks io;
   void* io_user_data;

   int read_from_callbacks;
   int buflen;
   ubyte[128] buffer_start;

   ubyte* img_buffer, img_buffer_end;
   ubyte* img_buffer_original, img_buffer_original_end;
}

struct stbi__result_info
{
   int bits_per_channel;
   int num_channels;
   int channel_order;
}

struct stbi__huffman
{
   ubyte[1 << FAST_BITS] fast;
   // weirdly, repacking this into AoS is a 10% speed loss, instead of a win
   ushort[256] code;
   ubyte[256]  values;
   ubyte[257]  size;
   uint[18] maxcode;
   int[17] delta;   // old 'firstsymbol' - old 'firstcode'
} 


struct stbi__jpeg
{
   stbi__context *s;
   stbi__huffman[4] huff_dc;
   stbi__huffman[4] huff_ac;
   ushort[4][64] dequant;
   short[4][1 << FAST_BITS] fast_ac;

// sizes for components, interleaved MCUs
   int img_h_max, img_v_max;
   int img_mcu_x, img_mcu_y;
   int img_mcu_w, img_mcu_h;

// definition of jpeg image component
   struct img_comp_struct
   {
      int id;
      int h,v;
      int tq;
      int hd,ha;
      int dc_pred;

      int x,y,w2,h2;
      ubyte* data;
      void *raw_data, raw_coeff;
      ubyte* linebuf;
      short *coeff;   // progressive only
      int coeff_w, coeff_h; // number of 8x8 coefficient blocks
   }

   img_comp_struct[4] img_comp;

   uint           code_buffer; // jpeg entropy-coded buffer
   int            code_bits;   // number of valid bits
   ubyte          marker;      // marker seen while filling entropy buffer
   int            nomore;      // flag if we saw a marker so must stop

   int            progressive;
   int            spec_start;
   int            spec_end;
   int            succ_high;
   int            succ_low;
   int            eob_run;
   int            jfif;
   int            app14_color_transform; // Adobe APP14 tag
   int            rgb;

   int scan_n;
   int[4] order;
   int restart_interval, todo;

// kernels
   void function(ubyte*, int, short*) idct_block_kernel;
   void function(ubyte*, ubyte*, ubyte*, ubyte*, int, int) YCbCr_to_RGB_kernel;
   ubyte* function(ubyte*, ubyte*, ubyte*, int, int) resample_row_hv_2_kernel;
}

ubyte* stbi_load(in string filename, int* x, int* y, int* comp, int req_comp)
{
   FILE* f = fopen(filename.ptr, "rb");
   ubyte* result;
   if (!f) println("Failed to open texture file ", filename);
   result = stbi_load_from_file(f,x,y,comp,req_comp);
   fclose(f);
   return result;
}

ubyte* stbi_load_from_file(FILE* f, int* x, int* y, int* comp, int req_comp)
{
   ubyte* result;
   stbi__context s;
   stbi__start_file(&s,f);
   result = stbi__load_and_postprocess_8bit(&s,x,y,comp,req_comp);
   if (result) {
      // need to 'unget' all the characters in the IO buffer
      fseek(f, - cast(int)(s.img_buffer_end - s.img_buffer), SEEK_CUR);
   }
   return result;
}

int stbi__stdio_read(void *user, char *data, int size)
{
   return cast (int) fread(data,1,size,cast(FILE*) user);
}

void stbi__stdio_skip(void *user, uint n)
{
   fseek(cast(FILE*) user, n, SEEK_CUR);
}

int stbi__stdio_eof(void *user)
{
   return feof(cast(FILE*) user);
}

void stbi__start_file(stbi__context* s, FILE* f)
{
    auto stbi__stdio_callbacks = stbi_io_callbacks(
       &stbi__stdio_read,
       &stbi__stdio_skip,
       &stbi__stdio_eof);
   stbi__start_callbacks(s, &stbi__stdio_callbacks, cast(void *) f);
}

void stbi__start_callbacks(stbi__context *s, stbi_io_callbacks *c, void *user)
{
   s.io = *c;
   s.io_user_data = user;
   s.buflen = s.buffer_start.sizeof;
   s.read_from_callbacks = 1;
   s.img_buffer_original = s.buffer_start.ptr;
   stbi__refill_buffer(s);
   s.img_buffer_original_end = s.img_buffer_end;
}

void stbi__refill_buffer(stbi__context *s)
{
   int n = s.io.read(s.io_user_data, cast(char*)s.buffer_start, s.buflen);
   if (n == 0) {
      // at end of file, treat same as if from memory, but need to handle case
      // where s.img_buffer isn't pointing to safe memory, e.g. 0-byte file
      s.read_from_callbacks = 0;
      s.img_buffer = s.buffer_start.ptr;
      s.img_buffer_end = s.buffer_start.ptr + 1;
      *s.img_buffer = 0;
   } else {
      s.img_buffer = s.buffer_start.ptr;
      s.img_buffer_end = s.buffer_start.ptr + n;
   }
}

ubyte* stbi__load_and_postprocess_8bit(stbi__context *s, int *x, int *y, int *comp, int req_comp)
{
   stbi__result_info ri;
   void *result = stbi__load_main(s, x, y, comp, req_comp, &ri, 8);

   if (result == null)
      return null;

   if (ri.bits_per_channel != 8) {
      assert(ri.bits_per_channel == 16);
      result = stbi__convert_16_to_8(cast(stbi__uint16 *) result, *x, *y, req_comp == 0 ? *comp : req_comp);
      ri.bits_per_channel = 8;
   }

   // @TODO: move stbi__convert_format to here

   if (stbi__vertically_flip_on_load) {
      int channels = req_comp ? req_comp : *comp;
      stbi__vertical_flip(result, *x, *y, channels * sizeof(stbi_uc));
   }

   return cast(ubyte*) result;
}

static immutable JPG = true;
static immutable PNG = true;
static immutable BMP = true;
static immutable GIF = true;

void *stbi__load_main(stbi__context *s, int *x, int *y, int *comp, int req_comp, stbi__result_info *ri, int bpc)
{
   memset(ri, 0, (*ri).sizeof); // make sure it's initialized if we add new fields
   ri.bits_per_channel = 8; // default is 8 so most paths don't have to be changed
   ri.channel_order = STBI_ORDER_RGB; // all current input & output are this, but this is here so we can add BGR order
   ri.num_channels = 0;

   static if(JPG)
       if (stbi__jpeg_test(s)) return stbi__jpeg_load(s,x,y,comp,req_comp, ri);
   static if(PNG)
       if (stbi__png_test(s))  return stbi__png_load(s,x,y,comp,req_comp, ri);
   static if(BMP)
       if (stbi__bmp_test(s))  return stbi__bmp_load(s,x,y,comp,req_comp, ri);
   static if(GIF)
       if (stbi__gif_test(s))  return stbi__gif_load(s,x,y,comp,req_comp, ri);

   return stbi__errpuc("unknown image type", "Image not of any known type, or corrupt");
}

int stbi__jpeg_test(stbi__context *s)
{
   int r;
   stbi__jpeg* j = cast(stbi__jpeg*)malloc(stbi__jpeg.sizeof);
   j.s = s;
   stbi__setup_jpeg(j);
   r = stbi__decode_jpet_header(j, STBI__SCAN_type);
   stbi__rewind(s);
   free(j);
   return r;
}

void stbi__setup_jpeg(stbi__jpeg *j)
{
   j.idct_block_kernel = &stbi__idct_block;
   j.YCbCr_to_RGB_kernel = &stbi__YCbCr_to_RGB_row;
   j.resample_row_hv_2_kernel = stbi__resample_row_hv_2;
//TODO: SIMD?
   /*
#ifdef STBI_SSE2
   if (stbi__sse2_available()) {
      j.idct_block_kernel = stbi__idct_simd;
      j.YCbCr_to_RGB_kernel = stbi__YCbCr_to_RGB_simd;
      j.resample_row_hv_2_kernel = stbi__resample_row_hv_2_simd;
   }
#endif

#ifdef STBI_NEON
   j.idct_block_kernel = stbi__idct_simd;
   j.YCbCr_to_RGB_kernel = stbi__YCbCr_to_RGB_simd;
   j.resample_row_hv_2_kernel = stbi__resample_row_hv_2_simd;
#endif */
}

int stbi__f2f(float x) { return cast(int) (x * 4096 + 0.5); }
int stbi__fsh(int x) { return x << 12; }


static ubyte stbi__clamp(int x)
{
   // trick to use a single test to catch both cases
   if (cast(uint) x > 255) {
      if (x < 0) return 0;
      if (x > 255) return 255;
   }
   return cast(ubyte) x;
}


void stbi__idct_block(ubyte* outval, int out_stride, short* data)
{
   int i;
   int[64] val;
   int *v = val.ptr;
   ubyte* o;
   short *d = data;

   // columns
   for (i=0; i < 8; ++i,++d, ++v) {
      // if all zeroes, shortcut -- this avoids dequantizing 0s and IDCTing
      if (d[ 8]==0 && d[16]==0 && d[24]==0 && d[32]==0
           && d[40]==0 && d[48]==0 && d[56]==0) {
         //    no shortcut                 0     seconds
         //    (1|2|3|4|5|6|7)==0          0     seconds
         //    all separate               -0.047 seconds
         //    1 && 2|3 && 4|5 && 6|7:    -0.047 seconds
         int dcterm = d[0] << 2;
         v[0] = v[8] = v[16] = v[24] = v[32] = v[40] = v[48] = v[56] = dcterm;
      } else {
           int t0,t1,t2,t3,p1,p2,p3,p4,p5,x0,x1,x2,x3; 
           p2 = d[16];                                    
           p3 = d[48];                                    
           p1 = (p2+p3) * stbi__f2f(0.5411961f);       
           t2 = p1 + p3*stbi__f2f(-1.847759065f);      
           t3 = p1 + p2*stbi__f2f( 0.765366865f);      
           p2 = d[0];                                    
           p3 = d[32];                                    
           t0 = stbi__fsh(p2+p3);                      
           t1 = stbi__fsh(p2-p3);                      
           x0 = t0+t3;                                 
           x3 = t0-t3;                                 
           x1 = t1+t2;                                 
           x2 = t1-t2;                                 
           t0 = d[48];                                    
           t1 = d[40];                                    
           t2 = d[24];                                    
           t3 = d[8];                                    
           p3 = t0+t2;                                 
           p4 = t1+t3;                                 
           p1 = t0+t3;                                 
           p2 = t1+t2;                                 
           p5 = (p3+p4)*stbi__f2f( 1.175875602f);      
           t0 = t0*stbi__f2f( 0.298631336f);           
           t1 = t1*stbi__f2f( 2.053119869f);           
           t2 = t2*stbi__f2f( 3.072711026f);           
           t3 = t3*stbi__f2f( 1.501321110f);           
           p1 = p5 + p1*stbi__f2f(-0.899976223f);      
           p2 = p5 + p2*stbi__f2f(-2.562915447f);      
           p3 = p3*stbi__f2f(-1.961570560f);           
           p4 = p4*stbi__f2f(-0.390180644f);           
           t3 += p1+p4;                                
           t2 += p2+p3;                                
           t1 += p2+p4;                                
           t0 += p1+p3;
         // constants scaled things up by 1<<12; let's bring them back
         // down, but keep 2 extra bits of precision
         x0 += 512; x1 += 512; x2 += 512; x3 += 512;
         v[ 0] = (x0+t3) >> 10;
         v[56] = (x0-t3) >> 10;
         v[ 8] = (x1+t2) >> 10;
         v[48] = (x1-t2) >> 10;
         v[16] = (x2+t1) >> 10;
         v[40] = (x2-t1) >> 10;
         v[24] = (x3+t0) >> 10;
         v[32] = (x3-t0) >> 10;
      }
   }

   for (i=0, v=val.ptr, o=outval; i < 8; ++i,v+=8,o+=out_stride) {
      // no fast case since the first 1D IDCT spread components out
   int t0,t1,t2,t3,p1,p2,p3,p4,p5,x0,x1,x2,x3; 
   p2 = v[2];                                    
   p3 = v[6];                                    
   p1 = (p2+p3) * stbi__f2f(0.5411961f);       
   t2 = p1 + p3 * stbi__f2f(-1.847759065f);      
   t3 = p1 + p2 *stbi__f2f( 0.765366865f);      
   p2 = v[0];                                    
   p3 = v[4];                                    
   t0 = stbi__fsh(p2+p3);                      
   t1 = stbi__fsh(p2-p3);                      
   x0 = t0+t3;                                 
   x3 = t0-t3;                                 
   x1 = t1+t2;                                 
   x2 = t1-t2;                                 
   t0 = v[7];                                    
   t1 = v[5];                                    
   t2 = v[3];                                    
   t3 = v[1];                                    
   p3 = t0+t2;                                 
   p4 = t1+t3;                                 
   p1 = t0+t3;                                 
   p2 = t1+t2;                                 
   p5 = (p3+p4)*stbi__f2f( 1.175875602f);      
   t0 = t0*stbi__f2f( 0.298631336f);           
   t1 = t1*stbi__f2f( 2.053119869f);           
   t2 = t2*stbi__f2f( 3.072711026f);           
   t3 = t3*stbi__f2f( 1.501321110f);           
   p1 = p5 + p1*stbi__f2f(-0.899976223f);      
   p2 = p5 + p2*stbi__f2f(-2.562915447f);      
   p3 = p3*stbi__f2f(-1.961570560f);           
   p4 = p4*stbi__f2f(-0.390180644f);           
   t3 += p1+p4;                                
   t2 += p2+p3;                                
   t1 += p2+p4;                                
   t0 += p1+p3;
      // constants scaled things up by 1<<12, plus we had 1<<2 from first
      // loop, plus horizontal and vertical each scale by sqrt(8) so together
      // we've got an extra 1<<3, so 1<<17 total we need to remove.
      // so we want to round that, which means adding 0.5 * 1<<17,
      // aka 65536. Also, we'll end up with -128 to 127 that we want
      // to encode as 0..255 by adding 128, so we'll add that before the shift
      x0 += 65536 + (128<<17);
      x1 += 65536 + (128<<17);
      x2 += 65536 + (128<<17);
      x3 += 65536 + (128<<17);
      // tried computing the shifts into temps, or'ing the temps to see
      // if any were out of range, but that was slower
      o[0] = stbi__clamp((x0+t3) >> 17);
      o[7] = stbi__clamp((x0-t3) >> 17);
      o[1] = stbi__clamp((x1+t2) >> 17);
      o[6] = stbi__clamp((x1-t2) >> 17);
      o[2] = stbi__clamp((x2+t1) >> 17);
      o[5] = stbi__clamp((x2-t1) >> 17);
      o[3] = stbi__clamp((x3+t0) >> 17);
      o[4] = stbi__clamp((x3-t0) >> 17);
   }
}

int stbi__float2fixed(float x)  { return cast(int) (x * 4096.0f + 0.5f) << 8; }


void stbi__YCbCr_to_RGB_row(ubyte* outval, const ubyte* y, const ubyte* pcb, const ubyte* pcr, int count, int step)
{
   int i;
   for (i=0; i < count; ++i) {
      int y_fixed = (y[i] << 20) + (1<<19); // rounding
      int r,g,b;
      int cr = pcr[i] - 128;
      int cb = pcb[i] - 128;
      r = y_fixed +  cr* stbi__float2fixed(1.40200f);
      g = y_fixed + (cr*-stbi__float2fixed(0.71414f)) + ((cb*-stbi__float2fixed(0.34414f)) & 0xffff0000);
      b = y_fixed                                     +   cb* stbi__float2fixed(1.77200f);
      r >>= 20;
      g >>= 20;
      b >>= 20;
      if (cast(uint) r > 255) { if (r < 0) r = 0; else r = 255; }
      if (cast(uint) g > 255) { if (g < 0) g = 0; else g = 255; }
      if (cast(uint) b > 255) { if (b < 0) b = 0; else b = 255; }
      outval[0] = cast(ubyte)r;
      outval[1] = cast(ubyte)g;
      outval[2] = cast(ubyte)b;
      outval[3] = 255;
      outval += step;
   }
}

ubyte stbi__div4(int x) { return cast(ubyte)(x >> 2); }
ubyte stbi__div16(int x) { return cast(ubyte)(x >> 4); }


ubyte* stbi__resample_row_hv_2(ubyte* outval, ubyte* in_near, ubyte* in_far, int w, int hs)
{
   // need to generate 2x2 samples for every one in input
   int i,t0,t1;
   if (w == 1) {
      outval[0] = outval[1] = stbi__div4(3*in_near[0] + in_far[0] + 2);
      return outval;
   }

   t1 = 3*in_near[0] + in_far[0];
   outval[0] = stbi__div4(t1+2);
   for (i=1; i < w; ++i) {
      t0 = t1;
      t1 = 3*in_near[i]+in_far[i];
      outval[i*2-1] = stbi__div16(3*t0 + t1 + 8);
      outval[i*2  ] = stbi__div16(3*t1 + t0 + 8);
   }
   outval[w*2-1] = stbi__div4(t1+2);
   return outval;
}

static immutable STBI__MARKER_none = 0xff;
bool stbi__DNL(int x) {         return (x) == 0xdc; }
bool stbi__SOI(int x) {         return (x) == 0xd8; }
bool stbi__EOI(int x) {         return (x) == 0xd9; }
bool stbi__SOF(int x) {         return (x) == 0xc0 || (x) == 0xc1 || (x) == 0xc2; }
bool stbi__SOS(int x) {         return (x) == 0xda; }

static immutable STBI__SCAN_load = 0, STBI__SCAN_type = 1, STBI__SCAN_header = 2;

int stbi__decode_jpeg_header(stbi__jpeg *z, int scan)
{
   int m;
   z.jfif = 0;
   z.app14_color_transform = -1; // valid values are 0,1,2
   z.marker = STBI__MARKER_none; // initialize cached marker to empty
   m = stbi__get_marker(z);
   if (!stbi__SOI(m)) return 0;
   if (scan == STBI__SCAN_type) return 1;
   m = stbi__get_marker(z);
   while (!stbi__SOF(m)) {
      if (!stbi__process_marker(z,m)) return 0;
      m = stbi__get_marker(z);
      while (m == STBI__MARKER_none) {
         // some files have extra padding after their blocks, so ok, we'll scan
         if (stbi__at_eof(z.s)) return 0;
         m = stbi__get_marker(z);
      }
   }
   z.progressive = stbi__SOF_progressive(m);
   if (!stbi__process_frame_header(z, scan)) return 0;
   return 1;
}

ubyte stbi__get_marker(stbi__jpeg *j)
{
    ubyte x;
   if (j.marker != STBI__MARKER_none) { x = j.marker; j.marker = STBI__MARKER_none; return x; }
   x = stbi__get8(j.s);
   if (x != 0xff) return STBI__MARKER_none;
   while (x == 0xff)
      x = stbi__get8(j.s); // consume repeated 0xff fill bytes
   return x;
}

ubyte stbi__get8(stbi__context *s)
{
   if (s.img_buffer < s.img_buffer_end)
      return *s.img_buffer++;
   if (s.read_from_callbacks) {
      stbi__refill_buffer(s);
      return *s.img_buffer++;
   }
   return 0;
}
