# UART em SystemVerilog

Projeto de uma UART com transmissao, recepcao e buffers FIFO para desacoplar o fluxo de dados entre logica de usuario e linha serial.

## Estrutura do projeto

- `UART.sv`: modulo de topo que integra gerador de baud, receptor, transmissor e duas FIFOs.
- `baud_gen.sv`: gera o tick de amostragem a partir do divisor `dvsr`.
- `receiver.sv`: maquina de estados de recepcao UART (start, dados e stop).
- `transmitter.sv`: maquina de estados de transmissao UART (start, dados e stop).
- `FIFO.sv`: wrapper da FIFO (controle + memoria).
- `FIFO_control.sv`: controle de ponteiros, flags `full`/`empty` e enderecos de leitura/escrita.
- `reg_file.sv`: memoria da FIFO.
- `tb_UART.sv`: testbench autovalidavel com loopback e checagem automatica.

## Visao de arquitetura

- RX:
  1. `receiver` converte o sinal serial `rx` em byte paralelo (`rx_data_out`).
  2. Quando um byte termina, ele e escrito na FIFO de RX.
  3. A logica externa le bytes pela interface `rd_uart` e recebe em `r_data`.

- TX:
  1. A logica externa escreve bytes com `wr_uart` e `w_data` na FIFO de TX.
  2. Quando ha dado disponivel, o `transmitter` inicia envio serial em `tx`.
  3. Ao fim de cada byte, a FIFO de TX avanca para o proximo.

## Parametros principais

No modulo `UART`:

- `DBIT` (default: 8): numero de bits de dados por frame.
- `SB_TICK` (default: 16): ticks por bit de stop (e base de oversampling).
- `FIFO_W` (default: 2): largura de endereco da FIFO. Profundidade = `2**FIFO_W`.

No `baud_gen`:

- `dvsr`: divisor de clock para gerar o tick de baud/oversampling.

## Interface do modulo de topo

Entradas:

- `clk`: clock do sistema.
- `rst_n`: reset ativo em nivel baixo.
- `rd_uart`: requisicao de leitura da FIFO de RX.
- `wr_uart`: requisicao de escrita na FIFO de TX.
- `rx`: entrada serial UART.
- `w_data[DBIT-1:0]`: byte para transmissao.
- `dvsr[10:0]`: valor do divisor para o gerador de tick.

Saidas:

- `tx_full`: indica FIFO de TX cheia.
- `rx_empty`: indica FIFO de RX vazia.
- `tx`: saida serial UART.
- `r_data[DBIT-1:0]`: dado lido da FIFO de RX.

## Exemplo de uso (sequencia)

1. Configure `dvsr` de acordo com clock e baud desejados.
2. Para transmitir, escreva bytes via `w_data` com pulso em `wr_uart`.
3. Monitore `tx_full` para evitar escrita quando FIFO de TX estiver cheia.
4. Para receber, cheque `rx_empty`; quando houver dado, pulse `rd_uart` e leia `r_data`.

## Testbench autovalidavel

Foi adicionado o arquivo `tb_UART.sv` com verificacao automatica (self-checking):

1. Instancia o `UART` de topo.
2. Faz loopback interno (`assign rx = tx`).
3. Escreve um vetor de bytes na FIFO de TX.
4. Le os bytes da FIFO de RX.
5. Compara byte a byte e encerra com `PASS` ou `FAIL` (`$fatal` em erro/timeout).

## Simulacao com Icarus Verilog (SystemVerilog)

Pre-requisito: Icarus Verilog com suporte a `-g2012`.

### Compilar

```bash
iverilog -g2012 -o uart_tb.out tb_UART.sv UART.sv baud_gen.sv receiver.sv transmitter.sv FIFO.sv FIFO_control.sv reg_file.sv
```

### Executar

```bash
vvp uart_tb.out
```

Saida esperada no sucesso:

```text
TESTE PASSOU: 4 bytes enviados e recebidos com sucesso.
```

Se houver erro de funcionalidade, o testbench aborta com `$fatal` mostrando mismatch ou timeout.

### Opcional: gerar forma de onda (VCD)

Se quiser depuracao visual, adicione no testbench:

```systemverilog
initial begin
  $dumpfile("uart_tb.vcd");
  $dumpvars(0, tb_UART);
end
```

Depois abra `uart_tb.vcd` no GTKWave.

## Observacoes

- O projeto usa reset assincrono ativo-baixo na maior parte dos modulos sequenciais.
- `SB_TICK` e `dvsr` devem ser coerentes com o baud rate alvo e frequencia de `clk`.
