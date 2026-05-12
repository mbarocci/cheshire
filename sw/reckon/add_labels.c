#include <stdio.h>
#include <stdlib.h>

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

#define TRAIN 1
#define VAL   0

int main (void) {

    FILE *ds_train = fopen(STR(TRAIN_DS_PATH), "r");
    FILE *labels_t = fopen(STR(TRAIN_LB_PATH), "r"); 
    FILE *new_ds_t = fopen("target/xilinx/memfile/aertrain_ds.mem", "w");

    FILE *ds_val   = fopen(STR(VAL_DS_PATH), "r");
    FILE *labels_v = fopen(STR(VAL_LB_PATH), "r");
    FILE *new_ds_v = fopen("target/xilinx/memfile/aerval_ds.mem", "w");

    char line[12], label_line[5];
    
    u_int32_t word, label_word, label=0, tick_n, tick_o, code; 

    int cnt = 0, ncnt =0;
    tick_n = 0;
    tick_o = 0;

    printf("Reading from:\n");
    printf("%s\n",STR(TRAIN_DS_PATH));
    printf("%s\n",STR(TRAIN_LB_PATH));
    printf("%s\n",STR(VAL_DS_PATH));
    printf("%s\n",STR(VAL_LB_PATH));

    for (int CURRENT_DS = 0; CURRENT_DS < 2 ; CURRENT_DS++) {
        
        if (CURRENT_DS == TRAIN) {
            cnt = 0;
            while (fgets(line, sizeof(line), ds_train)) {
                
                word = (u_int32_t)strtoul(line, NULL, 16);
                code = (word >> 24) & 0xFF;
                // printf("%08X\n", word);
                // printf("%d\n", code); 
                if (code == 1) {                                                                                                                                                                                                                
                    tick_n = 0;
                    // printf("End of sample %d, label %d", cnt, label);
                    cnt++;
                } else {tick_n = word & 0x00000FFF;}
                
                if ((tick_o < LABEL_DELAY) & (tick_n >= LABEL_DELAY) & (code == 3)) {                                                                                                                                                                
                    fgets(label_line, sizeof(label_line), labels_t);                                                                                                                                                                               
                    label = (u_int32_t)strtoul(label_line, NULL, 10);
                    //printf("Line: %s - label: %d\n", label_line, label);                                                                                                                                                                           
                    label_word = 0x02000000 | (label << 12);                                                                                                                                                                   
                    fprintf(new_ds_t, "%08X\n", label_word);                                                                                                                                                                                       
                    //printf("%08X\n", label_word);                                                                                                                                                                                                            
                }                                                                                                                                                                                                                                  
                                                                                                                                                                                                                                                
                fprintf(new_ds_t, "%08X\n", word);                                                                                                                                                                                                 
                tick_o = tick_n;                                                                                                                                                                                                                   
            }

        }
        else {
        // Read line by line until fgets returns NULL (EOF)                                                                                                                                                                                    
            while (fgets(line, sizeof(line), ds_val)) {                                                                                                                                                                                            
                // Print the line (fgets includes the newline character if it fits)                                                                                                                                                                
                cnt++;                                                                                                                                                                                                                             
                word = (u_int32_t)strtoul(line, NULL, 16);                                                                                                                                                                                         
                code = (word >> 24) & 0xFF;                                                                                                                                                                                                        
                                                                                                                                                                                                                                                
                if (code == 0x01) {                                                                                                                                                                                                                
                    tick_n = 0;                                                                                                                                                                                                                    
                    //ncnt = cnt;                                                                                                                                                                                                                    
                    // printf("\n%d ", cnt);
                    cnt++;                                                                                                                                                                                                         
                } else {tick_n = word & 0x00000FFF;}                                                                                                                                                                                               
                                                                                                                                                                                                                                                
                if ((tick_o < LABEL_DELAY) & (tick_n >= LABEL_DELAY) & (code == 3)) {                                                                                                                                                                
                    fgets(label_line, sizeof(label_line), labels_v);                                                                                                                                                                               
                    label = (u_int32_t)strtoul(label_line, NULL, 10);
                    //printf("Line: %s - label: %d\n", label_line, label);                                                                                                                                                                           
                    label_word = 0x02000000 | (label << 12);                                                                                                                                                                   
                    fprintf(new_ds_v, "%08X\n", label_word);                                                                                                                                                                                       
                    //printf("%08X\n", label_word);                                                                                                                                                                                                            
                }                                                                                                                                                                                                                                  
                                                                                                                                                                                                                                                
                fprintf(new_ds_v, "%08X\n", word);                                                                                                                                                                                                 
                tick_o = tick_n;                                                                                                                                                                                                                   
            }
        }                                                                                                                                                                                                                                  
        if (CURRENT_DS == TRAIN) {
            fclose(ds_train);                                                                                                                                                                                                                        
            fclose(labels_t);                                                                                                                                                                                                                      
            fclose(new_ds_t);
        } else {
            fclose(ds_val);                                                                                                                                                                                                                        
            fclose(labels_v);                                                                                                                                                                                                                      
            fclose(new_ds_v);
        }
    }
}