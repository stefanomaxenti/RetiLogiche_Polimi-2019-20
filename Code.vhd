----------------------------------------------------------------------------------
-- PROGETTO DI RETI LOGICHE - 2020                                              --
-- stefano.maxenti@mail.polimi.it - 10526141                                    --
-- ivan.motasov@mail.polimi.it    - 10563149                                    --
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- ==============================> MODULO ESTENDIBILE <=========================================
--package costants is
--    constant NUMBER_WZ              : integer                       := 8;
--    constant SIZE_WZ                : integer                       := 4;
--    constant ADDR_IN_RAM_POSITION   : std_logic_vector(15 downto 0) := "0000000000001000";
--    constant WZ_FACTOR_MULTIPLY     : integer                       := 16;
--    constant SIZE_ADDRESSES         : integer                       := 8;
--    constant WZ_BIT_INT             : integer                       := 128;
--end costants;
--
--library IEEE;
--use IEEE.STD_LOGIC_1164.all;
--use ieee.std_logic_unsigned.all;
--use ieee.numeric_std.all;
--use work.costants.all;

--entity project_reti_logiche   is 
--    port   ( 
--         i_clk       :   in    std_logic; --clock in ingresso generato dal testbench
--         i_start     :   in    std_logic; --segnale di start generato dal testbench
--         i_rst       :   in    std_logic; --segnale di reset che inizializza la macchina pronta per ricevere il primo segnale
--         i_data      :   in    std_logic_vector(SIZE_ADDRESSES-1 downto 0); --vettore che arriva dalla memoria in seguito ad una richiesta di lettura
--         o_address   :   out   std_logic_vector(15 downto 0); --vettore di output che manda l'indirizzo alla memoria
--         o_done      :   out   std_logic; --segnale di uscita che comunica la fine dell'elaborazione e il dato di uscita scritto
--         o_en        :   out   std_logic; --segnale di enable da dover mandare alla memoria per poter comunicare, sia in ingresso che in uscita
--         o_we        :   out   std_logic; --WRITE ENABLE, va mandato =1 alla memoria per poter scriverci; per leggere da memoria deve essere =0;
--         o_data      :   out   std_logic_vector(SIZE_ADDRESSES-1 downto 0) --segnale di uscita dal componente verso la memoria
--            ); 
--end   project_reti_logiche;
-- ==============================> MODULO ESTENDIBILE <=========================================

entity project_reti_logiche   is 
    port   ( 
         i_clk       :   in    std_logic; --clock in ingresso generato dal testbench
         i_start     :   in    std_logic; --segnale di start generato dal testbench
         i_rst       :   in    std_logic; --segnale di reset che inizializza la macchina pronta per ricevere il primo segnale
         i_data      :   in    std_logic_vector(7 downto 0); --vettore che arriva dalla memoria in seguito ad una richiesta di lettura
         o_address   :   out   std_logic_vector(15 downto 0); --vettore di output che manda l'indirizzo alla memoria
         o_done      :   out   std_logic; --segnale di uscita che comunica la fine dell'elaborazione e il dato di uscita scritto
         o_en        :   out   std_logic; --segnale di enable da dover mandare alla memoria per poter comunicare, sia in ingresso che in uscita
         o_we        :   out   std_logic; --WRITE ENABLE, va mandato =1 alla memoria per poter scriverci; per leggere da memoria deve essere =0;
         o_data      :   out   std_logic_vector(7 downto 0) --segnale di uscita dal componente verso la memoria
            ); 
end   project_reti_logiche;


architecture Behavioral of project_reti_logiche is

-- da rimuovere per utilizzare il modulo estendibile automatico         --
    constant NUMBER_WZ              : integer                       := 8;
    constant SIZE_WZ                : integer                       := 4;
    constant ADDR_IN_RAM_POSITION   : std_logic_vector(15 downto 0) := "0000000000001000";
    constant WZ_FACTOR_MULTIPLY     : integer                       := 16;
    constant SIZE_ADDRESSES         : integer                       := 8;
    constant WZ_BIT_INT             : integer                       := 128;
-- ------------------------------------------------------------------------

    type state_type is (ENDING, RESET, WAIT_FOR_START, GET_ADDR, WAIT_FOR_FIRST_WZ, GET_WZ_GENERIC_AND_COMPUTE, FOUND_OUTPUT, NOT_FOUND_OUTPUT, ENCODING);--, ENCODING);--, NOT_FOUND_OUTPUT, WRITING, ENDING);
    signal next_state       : state_type := RESET;
    signal addr             : std_logic_vector(SIZE_ADDRESSES-1 downto 0);
    signal next_o_address   : std_logic_vector(15 downto 0);
    signal counter          : integer range 0 to NUMBER_WZ+1;
    
    begin
    process(i_clk, i_rst)
        begin
           if(i_rst='1') then
                next_state <= RESET;
           elsif(rising_edge(i_clk)) then
                case next_state is
                
                   when RESET =>
                        counter <= 0;
                        o_en <= '1';
                        o_we <= '0';
                        o_done <= '0';
                        addr <= (others => '0');
                        o_data <= (others => '0');
                        next_o_address <= std_logic_vector(to_unsigned(2, 16));
                        o_address <= ADDR_IN_RAM_POSITION;
                        next_state <= WAIT_FOR_START;
                   
                   when WAIT_FOR_START =>
                        if(i_start = '1') then
                            next_state <= GET_ADDR;   
                        end if;
                        
                   when GET_ADDR =>
                        addr <= i_data;
                        o_address <= std_logic_vector(to_unsigned(0, 16));
                        next_state <= WAIT_FOR_FIRST_WZ;
                   
                   when WAIT_FOR_FIRST_WZ =>
                        o_address <= std_logic_vector(to_unsigned(1, 16));
                        next_state <= GET_WZ_GENERIC_AND_COMPUTE;
                        
                   when GET_WZ_GENERIC_AND_COMPUTE =>
                        if (counter < NUMBER_WZ) then
                            if (addr >= i_data AND addr < i_data + SIZE_WZ) then
                                next_state <= FOUND_OUTPUT;
                                o_address <= next_o_address - 2;
                            else
                                next_o_address <= next_o_address + 1;
                                counter <= counter +1;
                                o_address <= next_o_address;
                            end if;
                        else
                            next_state <= NOT_FOUND_OUTPUT;
                            --o_address <= std_logic_vector(to_unsigned(NUMBER_WZ+1, 16));
                        end if;
                    
                    when FOUND_OUTPUT =>
                         next_state <= ENCODING;
                         --o_address <= std_logic_vector(to_unsigned(NUMBER_WZ+1, 16));
                           
                    when ENCODING =>
                         o_data <= WZ_BIT_INT + std_logic_vector(to_unsigned(WZ_FACTOR_MULTIPLY*(counter), SIZE_ADDRESSES)) + std_logic_vector(shift_left(to_unsigned(1, SIZE_WZ), conv_integer(addr(SIZE_WZ-1 downto 0) - i_data(SIZE_WZ-1 downto 0))));
                         o_we <= '1';
                         o_address <= std_logic_vector(to_unsigned(NUMBER_WZ+1, 16));
                         next_state <= ENDING;
                           
                    when NOT_FOUND_OUTPUT =>
                         o_data <= addr;
                         o_we <= '1';
                         o_address <= std_logic_vector(to_unsigned(NUMBER_WZ+1, 16));
                         next_state <= ENDING;
                           
                    when ENDING =>
                         o_done <= '1';
                         if (i_start = '0') then
                            o_done <= '0';
                            o_we <= '0';
                            next_state <= RESET;
                         end if;
                
                    end case;
            end if;
        end process;     
end Behavioral;